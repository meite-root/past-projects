/*========================================================================
Title: 6_Analysis_3_choicemodel.do
Author: Hassane Meite
**# Bookmark #1
Date created: Tue 4 Apr 2023
Date last updated: Fri 16 Jun 2023
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
  log using ${code}6_Analysis_choicemodel.log, replace
  display c(current_time) 
  
  
*=========================================================================
* 1. Drop duplicates and Create new variables in financial data
*=========================================================================

*1. Add new variables and and save files
forvalues j=2020(-1) 2005 {

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
  //   save ${merged}FL_EDs_neighbor_finance_`j'_edited.dta, replace
  if `j' == 2020 { 
	save ${merged}FL_EDs_neighbor_finance_all_edited.dta, replace
	}
	else {
		append using ${merged}FL_EDs_neighbor_finance_all_edited.dta, force
		save ${merged}FL_EDs_neighbor_finance_all_edited.dta, replace
		}

  }
 
   // Save Per year
  use ${merged}FL_EDs_neighbor_finance_all_edited.dta, clear  
  forvalues j=2005(1) 2020 {
  preserve 
  keep if year ==`j' 
  save ${merged}FL_EDs_neighbor_finance_`j'_edited.dta, replace
  restore
  }
  
*4. Pivate equity data  
  use ${equity}predicted_pe.dta, clear
  egen tag= tag(ed_faclnbr)
  drop if tag != 1
  drop tag 
  save ${merged}predicted_pe_edited.dta, replace


 
 
*======================================================================
* 2. Create physician-year observations to capture movement every year
*======================================================================
  
* 1. Load wide dataset
  use ${edclaims}new_ED_physicians_2006_to_2020.dta, clear

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
  replace endpoint=0 if endpoint ==. // 2020 observations
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
  long as we can see them (2020).
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
* 2. Merge Physicians Cohorts to financial information (next_facility as ID)
*=========================================================================
 
* 0. Set up variables so that financial information for the next year's facility is taken
  rename ed_faclnbr current_ed_faclnbr
  rename next_facility ed_faclnbr
  
* 1. Loop through each year to add financial information
  
forvalues j=2020 (-1) 2006 {
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
  keepusing(zip ru2003 geoid10 ///
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

// * e. Classify type of control
//   gen control_notfp = (a1_control_type =="RELIGIOUS" || a1_control_type =="OTHER" || a1_control_type =="OTHER:")
//   gen control_invst = (a1_control_type =="INDIVIDUAL" || a1_control_type =="PARTNERSHIP" || a1_control_type =="CORPORATION")
//   gen control_govmt = (a1_control_type =="CITY" || a1_control_type =="CITY/COUNTY" || a1_control_type =="COUNTY" || a1_control_type =="HOSPITAL AUTH." || a1_control_type =="HOSPITAL" || a1_control_type =="HOSPITAL DISTRICT" || a1_control_type =="STATE")
  //   br a1_control_type control_notfp  control_invst  control_govmt control_other
  
  
* 4. save  
  if `j' == 2020 {
	compress
	save ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, replace
	}
	else {
		compress
		append using ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, force
		sort attenphyid year 
		save ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, replace
		}
  restore
}


clear


*=========================================================================
* 3. Remove edited financial data
*=========================================================================

  forvalues j=2005/2020 {
erase ${merged}FL_EDs_neighbor_finance_`j'_edited.dta
  }
 
erase ${merged}predicted_pe_edited.dta


*=========================================================================
* 4. Merge in salaries data   
*=========================================================================

* 1. Load dataset 
  use ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, clear

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
   save ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, replace  


*=========================================================================
* 5. Label All variables 
*=========================================================================
 
* 1. Load dataset 
  use ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, clear

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
  
  label var tot_vol "Work volume: Total number of patients (ks)"
  label var num_EDs "Number of EDs Physician works in"
  label var vol_per_ED "Total work volume per practice ED"
  * Hospital Variables
  label var current_ed_faclnbr "Facility ID number of the primary ED in given year" 
  label var ed_faclnbr "Facility ID number of the primary ED in the following year" 
  label var geoid10 "Facility location ID"
  label var pe "Private equity contract"
  label var ptsday "Patients per day"
  label var benefits_per_FTE "Benefits per full time employee"
  label var a1_control_type "Hospital control type "
//   label var control_notfp "Hospital control type: Not for Profit" 
//   label var control_invst "Hospital control type: Investor-owned" 
//   label var control_govmt "Hospital control type: Government"
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
   save ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, replace  
   clear
   
  
  
*===========================================================================
* 6. Set up model for cmclogit
*===========================================================================
  
  
  
/*------ ID FOR EACH ED -------*/


*1. Identify each unique facility accros years with ed_id
  use ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, clear

  
*2. Dropping unusable observations
  drop if year == 2020  // Dropping last observations: Cannot be observed the following year
  drop if leave_FL == 1  // Leaving the next year: Not to be included in cmclogit
  tab ed_faclnbr if missing(geoid10) // 125 observations (out of 11,000+) of physicians working at facilities (19 facilities) with no match  from financial/neighbourhood data
  drop if missing(geoid10) // Dropping the  125 observations: can't be used for cmc logit
  
*3. Choosing unique ID for each facility 
  egen ed_id = group (ed_faclnbr)
  label var ed_id "Facility unique ID"
  tab ed_id // 288 facilities
  order attenphyid year ed_faclnbr ed_id ed_faclnbr geoid10
  sort attenphyid year

*4. Save
  save ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, replace

  

  
  

  /*------ RESHAPE WIDE: CHOICESET (of a specific variable) PER YEAR -------*/
 
  * 1. Keep variable of interest
  use ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, clear
 
  * 2. Reduce dataset to ed-year format
  egen tag= tag(ed_id year)
  keep if tag ==1
  drop tag
 
  // ===============================================================
  //  Separate EDs into categories: 
  // 1. CONTROL TYPE: for profit/government/private
  // 2. RURAL / URBAN / SUBURBAN
  // 3. SIZE
  //  come up with categories
  // Potential error: Choice set not consistent: group option maybe
  // Potential error: I don't reduce dataset to relocate=1
  // =================================================================
 
  ** a. Control type
  keep ed_id ed_faclnbr year a1_control_type 
  order ed_id ed_faclnbr year
  sort ed_id year
  
   
  * 3. Balancing A: Filling gaps in panel Adding remaing years for remaining EDs (using carryforward)
  // 288 EDs; few appear in our list all 14 years. Balancing the panel:
  xtset ed_id year
  tsfill, full 
  by ed_id: gen nyear =[_N]
  tab nyear
  drop nyear
  
  // "Carry backward"
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  bysort ed_id (ed_faclnbr): replace a1_control_type=a1_control_type[_n+1] if missing(a1_control_type)
  
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  // bysort ed_faclnbr (ed_id_nbr): replace ed_id=ed_id[_n-1] if ed_id==.
  
  * 4. Balancing B: Filling in hospital data 
  merge 1:1 ed_faclnbr year using "${merged}FL_EDs_neighbor_finance_all_edited.dta", keepusing(a1_control_type)
  sort ed_id year
  drop if _merge == 2
  drop _merge
   
  * 5. 
  gen control_notfp = (a1_control_type =="RELIGIOUS" || a1_control_type =="OTHER" || a1_control_type =="OTHER:")
  gen control_invst = (a1_control_type =="INDIVIDUAL" || a1_control_type =="PARTNERSHIP" || a1_control_type =="CORPORATION")
  gen control_govmt = (a1_control_type =="CITY" || a1_control_type =="CITY/COUNTY" || a1_control_type =="COUNTY" || a1_control_type =="HOSPITAL AUTH." || a1_control_type =="HOSPITAL" || a1_control_type =="HOSPITAL DISTRICT" || a1_control_type =="STATE")
 
  // 3. RESHAPE WIDE per year 
 drop ed_faclnbr a1_control_type
 reshape wide control_notfp control_invst control_govmt, i(year) j(ed_id)
  
  // 4. Save
  save ${merged}FL_EDs_neighbor_finance_peryearchoice_controltype.dta, replace
    

  
  
 /*------ RESHAPE LONG: CHOICE PER OBSERVATION -------*/
  
  use ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, clear

*5. conditional logit setup: RESHAPE LONG
  gen id = _n 
  order id 
 
*6. Keep key variables 
  //   keep id attenphyid year ed_id ed_faclnbr geoid10  
  keep id year experience num_EDs ed_id
  order id year experience num_EDs ed_id
  tabulate ed_id, generate(choice) 
  // 288 choices of hospitals (Our sample)

  
*7. Merge in ALTERNATIVE-SPECIFIC variable 
//    merge m:1 year using "${merged}FL_EDs_neighbor_finance_peryearchoice_controltype.dta"
   merge m:1 year using "${merged}FL_EDs_neighbor_finance_peryearchoice_urbanindex.dta"
   
   drop _merge 
   
*7. Reshape LONG  
//   reshape long choice control_notfp control_invst control_govmt, i(id) j(alternative)
  reshape long choice rural urban metro, i(id) j(alternative)
  save ${merged}EM_physician_years_2006_to_2020_choicemodel_reshaped2.dta, replace

 

 
  
 /*
 
 
*===============================================================================
* 7. Run cmclogit analysis
*===============================================================================


* 1. Load Physicians dataset 
  use ${merged}EM_physician_years_2006_to_2020_choicemodel_reshaped.dta, clear

* 2. Experience bins
  gen exp_bin=1 if experience<4
  replace exp_bin=2 if experience>3 & experience<8
  replace exp_bin=3 if experience>7 & experience<12
  replace exp_bin=4 if experience>11
  
* 2.Conditional logit estimation 
  cmset id alternative // Declare data to be cross-sectional choice model data
  
  
  
  eststo table1: cmclogit choice control_notfp control_invst, ///
  iter(20) casevars(exp_bin) // experience and num_EDs as case-specific 
 
  margins, dydx(experience) 
 
  * Table 1 
  esttab table1 table2 table3 table4 ///
  using ${results}cmctable.tex, ///
  b(3) se(3) stats(r2 N, fmt(%4.3f %9.0fc) /// 
  labels("\$R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) /// 
  title("Conditional Logit Estimates of the location choices of 7 cohorts of Florida ED physicians between 2008 and 2020") ///
  mtitles() ///
  replace
 
 // what's the mean share of 
 // should find that the intr. between physician exp. and for-profit 

 
 
 */
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 /*
 
  .d8b.  d8888b.  .o88b. db   db d888888b db    db d88888b 
d8' `8b 88  `8D d8P  Y8 88   88   `88'   88    88 88'     
88ooo88 88oobY' 8P      88ooo88    88    Y8    8P 88ooooo 
88~~~88 88`8b   8b      88~~~88    88    `8b  d8' 88~~~~~ 
88   88 88 `88. Y8b  d8 88   88   .88.    `8bd8'  88.     
YP   YP 88   YD  `Y88P' YP   YP Y888888P    YP    Y88888P 

 */
 
 
 
 
 

 
/* 
*===============================================================================
* 6. Run cmclogit analysis
*===============================================================================

* 1. Load 
  use ${merged}cmclogit_ED_physicians_2006_to_2020.dta, clear

* 2.Conditional logit estimation 
  cmset id alternative // Declare data to be cross-sectional choice model data
 
  // First round
  eststo table1: cmclogit choice hosp_revenue ed_salary res_salary, ///
  iter(20)
 
  // Second round
  eststo table2: cmclogit choice hosp_revenue ed_salary res_salary, ///
  iter(20) casevars(vol_per_ED1_start ) // added work volume in starting ED as case-specific 
 
  // Third round
  eststo table3: cmclogit choice hosp_revenue ed_salary res_salary patientspday, ///
  iter(20)  
 
  // Fourth round
  eststo table4: cmclogit choice hosp_revenue ed_salary res_salary patientspday empbenefits, iter(20) 
 
 
  * Table 1 
  esttab table1 table2 table3 table4 ///
  using ${results}cmctable.tex, ///
  b(3) se(3) stats(r2 N, fmt(%4.3f %9.0fc) /// 
  labels("\$R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) /// 
  title("Conditional Logit Estimates of the location choices of 7 cohorts of Florida ED physicians between 2008 and 2020") ///
  mtitles() ///
  replace
 */


 
 
 /* 
  /*------ RESHAPE WIDE: CHOICESET (of a specific variable) PER YEAR -------*/
 
  * 1. Keep variable of interest
  use ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, clear
 
  * 2. Reduce dataset to ed-year format
  egen tag= tag(ed_id year)
  keep if tag ==1
  drop tag
 
  // ===============================================================
  //  Separate EDs into categories: 
  // 1. CONTROL TYPE: for profit/government/private
  // 2. RURAL / URBAN / SUBURBAN
  // 3. SIZE
  //  come up with categories
  // Potential error: Choice set not consistent: group option maybe
  // Potential error: I don't reduce dataset to relocate=1
  // =================================================================
 
  ** a. Control type
  keep ed_id ed_faclnbr year ru2003
  order ed_id ed_faclnbr year
  sort ed_id year
  
   
  * 3. Balancing A: Filling gaps in panel Adding remaing years for remaining EDs (using carryforward)
  // 288 EDs; few appear in our list all 14 years. Balancing the panel:
  xtset ed_id year
  tsfill, full 
  by ed_id: gen nyear =[_N]
  tab nyear
  drop nyear
  
  // "Carry backward"
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  bysort ed_id (ed_faclnbr): replace ru2003=ru2003[_n+1] if missing(ru2003)
  
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  bysort ed_id (ed_faclnbr): replace ed_faclnbr=ed_faclnbr[_n+1] if missing(ed_faclnbr)
  // bysort ed_faclnbr (ed_id_nbr): replace ed_id=ed_id[_n-1] if ed_id==.
  
  * 4. Balancing B: Filling in hospital data 
  merge 1:1 ed_faclnbr year using "${merged}FL_EDs_neighbor_finance_all_edited.dta", keepusing(ru2003)
  sort ed_id year
  drop if _merge == 2
  drop _merge
   
  * 5. 
  gen rural = (ru2003 >= 8)
  gen urban = (4 <= ru2003 & ru2003 <= 7)
  gen metro = (ru2003 <= 3)
  
  // 3. RESHAPE WIDE per year 
 drop ed_faclnbr ru2003
 reshape wide rural urban metro, i(year) j(ed_id)
  
  // 4. Save
  save ${merged}FL_EDs_neighbor_finance_peryearchoice_urbanindex.dta, replace

*/
  
  
/* LAST ATTEMPT AT CMCLOGIT

*1. Load  
  use ${merged}EM_physician_years_2006_to_2020_choicemodel.dta, clear

*2. conditional logit setup: RESHAPE LONG
  gen id = _n 
  order id 
 
*3. Keep key variables 
  //   keep id attenphyid year ed_id ed_faclnbr geoid10  
  keep id year experience num_EDs  a1_control_type relocate_FL
  order id year experience num_EDs a1_control_type relocate_FL
  tabulate ed_id, generate(choice) 
  // 288 choices of hospitals (Our sample)

*3. Keep key variables   
  replace a1_control_type = "NOT FOR PROFIT" if (a1_control_type =="RELIGIOUS" || a1_control_type =="OTHER" || a1_control_type =="OTHER:")
  replace a1_control_type = "INVESTORS" if (a1_control_type =="INDIVIDUAL" || a1_control_type =="PARTNERSHIP" || a1_control_type =="CORPORATION")
  replace a1_control_type = "GOVERNMENT" if (a1_control_type =="CITY" || a1_control_type =="CITY/COUNTY" || a1_control_type =="COUNTY" || a1_control_type =="HOSPITAL AUTH." || a1_control_type =="HOSPITAL" || a1_control_type =="HOSPITAL DISTRICT" || a1_control_type =="STATE")
  
*4. CMC Setup  
  encode a1_control_type, generate(control_type)
  tabulate control_type, generate(choice) 
  drop control_type a1_control_type
  generate control_type1 = "GOVERNMENT"
  generate control_type2 = "INVESTORS"
  generate control_type3 = "NOT FOR PROFIT"
  reshape long choice control_type, i(id) j(alternative)

* 5. Experience bins
  gen exp_bin=1 if experience<4
  replace exp_bin=2 if experience>3 & experience<8
  replace exp_bin=3 if experience>7 & experience<12
  replace exp_bin=4 if experience>11

* 6.Clean up
  drop if missing(control_type)
  drop year experience num_EDs
  order id exp_bin relocate_FL alternative control_type
  
* 2.Conditional logit estimation 
  cmset id control_type // Declare data to be cross-sectional choice model data
  eststo table1: cmclogit choice, casevars(i.relocate_FL i.exp_bin)
  
  /*
