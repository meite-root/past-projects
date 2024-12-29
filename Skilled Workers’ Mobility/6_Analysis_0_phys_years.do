/*========================================================================
Title: 6_Analysis_0_phys_years.do
Author: Hassane Meite
Date created: Mon 9 May 2022
Date last updated: Sun 30 Jul 2023
========================================================================*/

*========================================================================
* 0. Set Global paths and create a log file for results
*=========================================================================

  cap log close
  clear
  set more off
  ssc install estout

* Set path
  global path "/data/jv947/Lab_Shared"
  
* Set folder subdirectories
  global edclaims "${path}/ED_claims/"
  global code "${path}/code/Hassane/"
  global data "${path}/FL_Hospital_Financial_Data/all_raw/"
  global merged "${path}/FL_Hospital_Financial_Data/stata/"
  global sheets "${path}/FL_Hospital_Financial_Data/stata/sheets/"
  global results "${path}/results/Hassane/"
  global financial "${path}/Master_FL_Hospital_List/working_data/"
  global licensedata "${path}/FL_Medical_License_Data/"
  global equity "${path}/Private_Equity_Data/"
  global cpi "${path}/CPI_Data/"
 
* Initialize log
  log using ${code}6_Analysis_0_phys_years.log, replace
  display c(current_time) 
  
    
*=========================================================================
* 1. Drop duplicates and Create new variables in financial data
*=========================================================================
  forvalues j=2005/2021 {

* Dropping dupplicates  
  use ${financial}FL_EDs_neighbor_finance_`j'.dta, clear
  bysort ed_faclnbr: keep if _n==1
  
* Variable: Staffing Ratio
  gen phys_num = b4_physemer/num_ED
  replace phys_num=0 if phys_num==.
  replace a2_ed_oncall=0 if a2_ed_oncall==.
  gen volume = a2_ed_inhous + a2_ed_oncall
  gen pat_per_ED=volume/num_ED
  gen staffing_ratio = pat_per_ED/phys_num
  gen ptsday = staffing_ratio/365
  replace ptsday=0 if ptsday==.
  label var ptsday "Patients per day"
  
* Variable: Total employee benefits per FTE worker: x1_totalben
  gen benefits=c3a_admindis_net_op_rev+c3a_employdis_net_op_rev+x1_totalben
  replace benefits=benefits/num_EDs
  replace c5_ftetotals=c5_ftetotals/num_EDs
  replace benefits=benefits/c5_ftetotals
  replace benefits=benefits/1000
  rename benefits benefits_per_FTE
  label var benefits_per_FTE "Benefits per full time employee ($ Thousands)"
* Save
  save ${merged}FL_EDs_neighbor_finance_`j'_edited.dta, replace
  }
  
* Pivate equity data  
  use ${equity}predicted_pe.dta, clear
  egen tag= tag(ed_faclnbr)
  drop if tag != 1
  drop tag 
  save ${merged}predicted_pe_edited.dta, replace


*======================================================================
* 2. Create physician-year observations to capture movement every year
*======================================================================
  
* 1. Load wide dataset
  use ${edclaims}new_ED_physicians_2006_to_2021.dta, clear

* 2. Reshape to long format
  gen work_yr1 = 1
  gen mfulltime_yr1 = 1 //! assumption
  local vars ///
  work_yr mfulltime_yr tot_vol_yr num_EDs_yr ed_faclnbr_yr vol_per_ED_yr
  reshape long `vars' , ///
  i(attenphyid attenphynpi start_year endpoint) j(year) string
  // Order
  destring(year), replace
  encode attenphyid, gen (attenphyid_e)
  sort attenphyid year
  order attenphyid attenphynpi attenphyid_e endpoint start_year year `vars'

* 3. Rename
  rename ed_faclnbr_yr ed_faclnbr
  rename work_yr work 
  rename mfulltime_yr mfulltime
  rename tot_vol_yr tot_vol 
  rename num_EDs_yr num_EDs  
   
* 4. Clean empty rows
  replace endpoint=0 if endpoint ==. // 2021 observations
  drop if year > endpoint+1 
  /*Removing empty rows/no obs: if endpoint is 1 (1 year 
  after the initial yr), then observations stop after year 2
  We therefore remove obs after y2 for the given physician*/ 

* 5. Create leave_FL (=1 if phys leaves the next yr)
  bysort attenphyid: gen leave_FL = work[_n] - work[_n+1] ///
  if work == 1 
  
  *Identify skip years
  // 1 yr skipped
  bysort attenphyid: gen skip_year = 1 ///
  if work==0 & work[_n+1]==1
  
  // 2 yrs skipped
  bysort attenphyid: replace skip_year = 1 ///
  if work==0 & skip_year[_n+1]==1
  
  // 3 yrs skipped
  bysort attenphyid: replace skip_year = 1 ///
  if work==0 & skip_year[_n+1]==1
 
 
  *Correct in case there are multiple leave years
  bysort attenphyid: replace leave_FL = 0 if skip_year[_n+1]==1
  bysort attenphyid: replace leave_FL = . if skip_year[_n]==1
  
  
  /*
  ^such observations (leaving FL and coming back) could arise due to 
  pregnancy/leave/training purposes. In any case, they do not fall in
  our description of leaving FL, which is exiting the FL market for as
  long as we can see them (2021).
  */


* 6. Create relocate_FL (=1 if phys switches primary work location)  
  // if 1 yr skipped
  bysort attenphyid: replace ed_faclnbr = ed_faclnbr[_n+1] ///
  if skip_year==1
  // if 2 yrs skipped
  bysort attenphyid: replace ed_faclnbr = ed_faclnbr[_n+1] ///
  if skip_year==1
  // if 3 yrs skipped
  bysort attenphyid: replace ed_faclnbr = ed_faclnbr[_n+1] ///
  if skip_year==1
   
  /* 
  ^ Assigns following year facility number to skip_year
  Conditional on being in FL; we want to ignore a missing year if the
  physician is still in Florida; that will allow comparison with the 
  physician practice facility after the skip year */

  bysort attenphyid: gen relocate_FL = (ed_faclnbr[_n] != ed_faclnbr[_n+1])  if work == 1 
  /* ^ Main code line*/
  
  bysort attenphyid: replace relocate_FL = . if skip_year[_n]==1
  bysort attenphyid: replace relocate_FL = 0 if leave_FL ==.
  /* ^ Clean*/
  
  bysort attenphyid: gen next_facility = ed_faclnbr[_n+1]
  /* ^ For CMC logit*/
  
* 7. Add experience variable for fixed effects 
  gen experience = year - 1

   
* 8. Drop observations that are not needed
  replace year = experience + start_year
  // Years were physician is not working
  drop if work==0
  drop skip_year // column
  
  
 *=========================================================================
* 2. Merge Physicians Cohorts to financial information
*=========================================================================
 
* 1. Loop through each year to add financial information
  
forvalues j=2021 (-1) 2006 {
  preserve
  //local lastest_start_year = $latest_start 
  
* a. Display for log readability  
  display "" 
  display "--------------" 
  display "year: " `j' 
  display "--------------" 
  display "" 

* b. Keep cohort of interest  
  keep if year==`j'

* c. Merging financial info
  local k=`j'-1
  merge m:1 ed_faclnbr using "${merged}FL_EDs_neighbor_finance_`k'_edited.dta", ///
  keepusing(zip ru2003 ///
  total_population total_housing occupied median_income ///
  poverty white black bachelors house_value median_age ///
  male_labor female_labor lpr_female lpr_male lbr_part ///
  a1_control_type ///
  b4_physemer b4_numbphys c2_tot_margin c5_swemerge c5_swtotals ///
  c6_swresearexp c6_swapstgraded c6_swnpstgraded c6_swhosptadm ///
  b4xtra_physemer_approved num_facilities ptsday benefits_per_FTE ///
  c5_fteemerge c5_ftetotals c6_fteresearexp c6_fteapstgraded ///
  c6_ftenpstgraded c6_ftehosptadm)
  // Assess merge
  tab _merge
  tab ed_faclnbr if _merge==1
  drop if _merge==2
  drop _merge 
  
* Add private equity variable
  merge m:1 ed_faclnbr using ${merged}predicted_pe_edited.dta, keepusing(pe)
  drop if _merge==2
  drop _merge
  
 
* d.1. Adjust financial information to reflect the fact that there are multiple facilities under one license number

  local vars_1 b4_physemer b4_numbphys c2_tot_margin c5_swemerge ///
  c5_swtotals c6_swapstgraded c6_swnpstgraded ///
  c6_swhosptadm c6_swresearexp ///
  c5_fteemerge c5_ftetotals c6_fteresearexp ///
  c6_fteapstgraded c6_ftenpstgraded c6_ftehosptadm

	foreach x of var `vars_1' { 
	replace `x' = `x'/num_facilities
	}

* d.2. Rescale variables to thousands
  local vars_2 ///
  c5_swemerge c6_swapstgraded c6_swnpstgraded house_value /// 
  c6_swresearexp median_income tot_vol total_population ///

  foreach x of var `vars_2' { 
	replace `x' = `x'/1000
	}

* d.3. Rescale specific variables to millions of dollars
  local vars_3 ///
	c2_tot_margin c5_swtotals c6_swhosptadm
  foreach x of var `vars_3' { 
	replace `x' = `x'/1000000
	}
	
* d.3. Create per FTE variables
  gen c5_swfte_emerge= c5_swemerge/c5_fteemerge
  gen c5_swfte_totals= (1000*c5_swtotals)/c5_ftetotals
  gen c6_swfte_apstgraded= c6_swapstgraded/c6_fteapstgraded
  gen c6_swfte_npstgraded= c6_swnpstgraded/c6_ftenpstgraded
  gen c6_swfte_hosptadm= (1000*c6_swhosptadm)/c6_ftehosptadm
  gen c6_swfte_researexp= c6_swresearexp/c6_fteresearexp

  drop c6_fteresearexp ///
  c6_fteapstgraded c6_ftenpstgraded  ///

* e. Classify type of control
  gen control_notfp = (a1_control_type =="RELIGIOUS")
  gen control_invst = (a1_control_type =="INDIVIDUAL" || a1_control_type =="PARTNERSHIP" || a1_control_type =="CORPORATION")
  gen control_govmt = (a1_control_type =="CITY" || a1_control_type =="CITY/COUNTY" || a1_control_type =="COUNTY" || a1_control_type =="HOSPITAL AUTH." || a1_control_type =="HOSPITAL" || a1_control_type =="HOSPITAL DISTRICT" || a1_control_type =="STATE")
  gen control_other = (a1_control_type =="OTHER" || a1_control_type =="OTHER:" )  
//   br a1_control_type control_notfp  control_invst  control_govmt control_other
  
* 4. save  
  if `j' == 2021 {
	compress
	save ${merged}EM_physician_years_2006_to_2021.dta, replace
	}
	else {
		compress
		append using ${merged}EM_physician_years_2006_to_2021.dta, force
		sort attenphyid year 
		save ${merged}EM_physician_years_2006_to_2021.dta, replace
		}
  restore
}

clear 



*=========================================================================
* 3. Remove edited financial data
*=========================================================================

  forvalues j=2005/2021 {
erase ${merged}FL_EDs_neighbor_finance_`j'_edited.dta
  }
  
erase ${merged}predicted_pe_edited.dta


*=========================================================================
* 4. Merge in salaries data   
*=========================================================================

* 1. Load dataset 
  use ${merged}EM_physician_years_2006_to_2021.dta, clear

* 2. Merge
  rename zip postal_code
  merge m:1 postal_code using ${merged}H1B_Perm_per_zipcode_salary.dta
   // Assess merge
  tab _merge
  tab postal_code if _merge==1
  drop if _merge==2
  drop _merge
  
* 3. Rescale variables to thousands of dollars   
  replace pw_median = pw_median/1000
  replace pw_mean = pw_mean/1000
  replace pw_95th = pw_95th/1000
  
* 4. Save  
   sort attenphyid_e year
   save ${merged}EM_physician_years_2006_to_2021.dta, replace  


*=========================================================================
* 5. Label All variables 
*=========================================================================
 
* 1. Load dataset 
  use ${merged}EM_physician_years_2006_to_2021.dta, clear
 
* 2. Label variables
  
  * Physician Variables
  label var attenphyid "Physician ID"
  label var attenphyid_e "Physician ID (encoded)"
  label var attenphynpi "Physician NPI"
  label var start_year " Starting year (=cohort)"
  label var year "Observation year"
  label var work "=1 if working in FL in the current year"
  label var mfulltime "=1 if fulltime in FL in the current year"
  label var leave_FL  "=1 if phys leaves the next yr"
  label var relocate_FL "=1 if phys switches primary work location"
  label var experience "Years of Experience"
  label var next_facility "Practice facility in the following year"
  label var tot_vol "Work volume: Total number of patients (ks)"
  label var num_EDs "Number of EDs Physician works in"
  label var vol_per_ED "Total work volume per practice ED"
  * Hospital Variables
  label var ed_faclnbr "Facility ID number of the primary ED in given year" 
  label var pe "Private equity contract"
  label var ptsday "Patients per day"
  label var benefits_per_FTE "Benefits per full time employee"
  label var a1_control_type "Hospital control type "
  label var control_notfp "Hospital control type: Not for Profit" 
  label var control_invst "Hospital control type: Investor-owned" 
  label var control_govmt "Hospital control type: Government"
  label var control_other "Hospital control type: Other"
  label var c2_tot_margin "c2 - Hospital net Revenue (Ms)"
  label var b4_numbphys "b4 - Total No. of physicians - Health Ed."
  label var b4_physemer "b4 - Number of EM physicians - Health Ed."
  label var b4xtra_physemer_approved "b4 - Approved program - EM (y/n)"
  label var c5_swemerge "c5 - Salary expense - Emerg. services (ks)"
  label var c5_swtotals "c5 - Salary expense - Tot. Patient Care Serv.(Ms)" 
  label var c6_swresearexp "c6 - Salary expense - research (ks)"
  label var c6_swapstgraded "c6 - Salary expense - approved GMEP (ks)"
  label var c6_swnpstgraded "c6 - Salary expense - non-approved GMEP (ks)"
  label var c6_swhosptadm "c6 - Salary expense - Hospital Admin. (Ms)"
  // Per Full time employee 
  label var c5_ftetotals "c5 - No. of FTE - Total Patient Care Services"
  label var c5_fteemerge " c5 - No. of FTE - Emergency Services"
  label var c6_ftehosptadm "c6 - No. of FTE - Hospital Administration"
  label var c5_swfte_emerge "c5 - Salary expense per FTE - Em. S (ks)"
  label var c5_swfte_totals "c5 - Salaries expense per FTE - Total (ks)"
  label var c6_swfte_researexp  "c6 - Salaries expense per FTE - research (ks)"
  label var c6_swfte_apstgraded "c6 - Salaries expense per FTE - app. GMEP (ks)"
  label var c6_swfte_npstgraded "c6 - Salaries expense per FTE - n-app GMEP (ks)"
  label var c6_swfte_hosptadm "c6 - Salaries expense per FTE - H. Admin. (ks)"
  * Zip-code level Health workers income
  label var pw_median "Zip Code Prevailing wage median (ks)"
  label var pw_mean "Zip Code Prevailing wage mean (ks)"
  label var pw_95th "Zip Code Prevailing wage 95th perc. (ks)"
  * Tract level
  label var ru2003 "2003 Rural-Urban Continuum code"
  label var median_income "Total Median Income per tract (ks)" 
  label var total_population "Estimate Total population per tract (ks)"
  label var poverty "Poverty rate per tract"
  label var white "Percentage white populaiton per tract"
  label var black "Percentage Black population per tract"
  label var bachelors "Percentage with Bachelors or higher"
  label var house_value "Median house value per tract (ks)"
  
* 3. Save  
   save ${merged}EM_physician_years_2006_to_2021.dta, replace  
   clear
   
   
*=========================================================================
* 6. Check pairwise correlations
*=========================================================================
 
* 1. Load dataset  
  use ${merged}EM_physician_years_2006_to_2021.dta, clear

* 2. Correlation tables 
 
  * Table 1: Physician Work Volume variables
  eststo corr_1: ///
  estpost correlate tot_vol ptsday pe num_EDs, matrix listwise
  esttab corr_1 using ${results}corr_table1.tex, ///
  unstack not noobs nostar compress ///
  title("Correlation table: Physician Work Volume variables") replace
  
  * Table 2 : Hospital Staff variables
  eststo corr_2: estpost correlate c5_ftetotals c6_ftehosptadm ///
  b4_numbphys b4_physemer b4xtra_physemer, matrix listwise
  esttab corr_2 using ${results}corr_table2.tex, ///
  unstack not noobs nostar compress ///
  title("Correlation table: Hospital Staff variables") replace

  * Table 3 : Hospital spending variables
  eststo corr_3: estpost correlate c2_tot_margin c5_swfte_emerge ///
  c6_swresearexp c5_swfte_totals c6_swfte_hosptadm , matrix listwise
  esttab corr_3 using ${results}corr_table3.tex, ///
  unstack not noobs nostar compress ///
  title("Correlation table: Hospital spending variables") replace
  
  * Table 4 : Mix
  eststo corr_4: estpost correlate ptsday c5_ftetotals ///
  b4_numbphys b4_physemer, matrix listwise
  esttab corr_4 using ${results}corr_table4.tex, ///
  unstack not noobs nostar compress ///
  title("Correlation table: Variabls mix") replace

  
