/*==============================================================================
Title: 6_Analysis.do
Author: Hassane Meite
Date created: Mon 9 May
Date last updated: Sun 27 Nov 2022
================================================================================*/

*===============================================================================
* 0. Set Global paths and create a log file for results
*===============================================================================

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
  log using ${code}6_Analysis_cohorts.log, replace
  display c(current_time) 
  
  

*===============================================================================
* 1. Drop duplicates and Create new variables in financial data
*===============================================================================

  forvalues j=2005/2020 {

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


*===============================================================================
* 2. Merge Physicians Cohorts to financial information
*===============================================================================
   
  
* 1. Load wide dataset
  use ${edclaims}new_ED_physicians_2006_to_2020.dta, clear

* 2. Select cutoff 
  scalar cutoff = 6
  global y = cutoff + 1 // cutoff_column
  global latest_start =  2020 - cutoff
  display $y
  display $latest_start
  
* 2. Keep rows of interest (if cutoff =6, we pick 7 as end year)  
  drop if start_year > $latest_start
  gen end_year = start_year + cutoff
  global cutofflist attenphyid attenphynpi start_year end_year ///
  ed_faclnbr_yr1 num_EDs_yr1 tot_vol_yr1 vol_per_ED_yr1 ///
  ed_faclnbr_yr$y num_EDs_yr$y tot_vol_yr$y vol_per_ED_yr$y work_yr$y 
  keep $cutofflist
  order $cutofflist
  
* 3. rename to start and end year 
  rename tot_vol_yr1 tot_vol_start   
  rename num_EDs_yr1 num_EDs_start
  rename ed_faclnbr_yr1 ed_faclnbr1_start
  rename vol_per_ED_yr1 vol_per_ED1_start
  
  rename tot_vol_yr$y tot_vol_end
  rename num_EDs_yr$y num_EDs_end
  rename ed_faclnbr_yr$y ed_faclnbr1_end
  rename vol_per_ED_yr$y vol_per_ED1_end
  rename work_yr$y work_end

 
* 4. Create variable for whether physicians switch their primary facility from start year to +cutoff 
  gen switch_end = (ed_faclnbr1_start != ed_faclnbr1_end)
  replace switch_end = . if missing(ed_faclnbr1_end)

* 5. Add medical care cpi variable
  gen year = start_year-1
  merge m:1 year using ${cpi}CPIMEDSL.dta, keepusing(cpimed)
  rename cpimed cpimed_start
  drop if _merge==2
  drop _merge
  replace year = end_year-1
  merge m:1 year using ${cpi}CPIMEDSL.dta, keepusing(cpimed)
  rename cpimed cpimed_end
  drop if _merge==2
  drop _merge year
  
  
* 6. Loop through each cohort to add financial information
  
forvalues j=$latest_start (-1) 2006 {
  preserve
  local lastest_start_year = $latest_start 
  
* a. Display for log readability  
  local i = `j'+ cutoff
  display "" 
  display "--------------" 
  display "Start year: " `j' 
  display "End year: " `i'
  display "--------------" 
  display "" 

* b. Keep cohort of interest  
  keep if start_year==`j'

* c.1 Merging start year financial info
  local k=`j'-1
  sort ed_faclnbr1_start
  rename ed_faclnbr1_start ed_faclnbr
  merge m:1 ed_faclnbr using "${merged}FL_EDs_neighbor_finance_`k'_edited.dta", ///
  keepusing(zip  ///
  total_population total_housing occupied median_income ///
  poverty white black bachelors house_value median_age ///
  male_labor female_labor lpr_female lpr_male lbr_part ///
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
 
  
  // Rename variables with prefix s_ for start year
  foreach e of varlist zip-pe {
  rename `e' `e'_start
  }  
  rename ed_faclnbr ed_faclnbr_start

  
* c.2 Merging end year financial info
  local l=`j'+ (cutoff-1)
  sort ed_faclnbr1_end
  rename ed_faclnbr1_end ed_faclnbr
  merge m:1 ed_faclnbr using "${merged}FL_EDs_neighbor_finance_`l'_edited.dta", ///
  keepusing(zip  ///
  total_population total_housing occupied median_income ///
  poverty white black bachelors house_value median_age ///
  male_labor female_labor lpr_female lpr_male lbr_part ///
  LICENSENUMBER b4_physemer b4_numbphys c2_tot_margin c5_swemerge c5_swtotals ///
  c6_swresearexp c6_swapstgraded c6_swnpstgraded c6_swhosptadm ///
  b4xtra_physemer_approved num_facilities ptsday benefits_per_FTE ///
  c5_fteemerge c5_ftetotals c6_fteresearexp c6_fteapstgraded ///
  c6_ftenpstgraded c6_ftehosptadm)
  
  // Assess merge
  tab _merge
  tab ed_faclnbr if _merge==1
  drop _merge
  
  
* Add private equity variable
  merge m:1 ed_faclnbr using ${merged}predicted_pe_edited.dta, keepusing(pe)
  drop if _merge==2
  drop _merge  
    
  
  // Rename variables with prefix e_ for end year
  foreach f of varlist zip-pe {
  rename `f' `f'_end
  }
  rename ed_faclnbr ed_faclnbr_end

 
* d.1. Adjust financial information to reflect the fact that there are multiple facilities under one license number
  
  local vars_st b4_physemer_start b4_numbphys_start c2_tot_margin_start c5_swemerge_start ///
  c5_swtotals_start c6_swapstgraded_start c6_swnpstgraded_start ///
  c6_swhosptadm_start c6_swresearexp_start ///
  c5_fteemerge_start c5_ftetotals_start c6_fteresearexp_start ///
  c6_fteapstgraded_start c6_ftenpstgraded_start c6_ftehosptadm_start
 
	foreach x of var `vars_st' { 
	replace `x' = `x'/num_facilities_start
	}
  
  local vars_nd b4_physemer_end b4_numbphys_end c2_tot_margin_end c5_swemerge_end ///
  c5_swtotals_end c6_swapstgraded_end c6_swnpstgraded_end ///
  c6_swhosptadm_end c6_swresearexp_end ///
  c5_fteemerge_end c5_ftetotals_end c6_fteresearexp_end ///
  c6_fteapstgraded_end c6_ftenpstgraded_end c6_ftehosptadm_end
        
	foreach x of var `vars_nd' { 
	replace `x' = `x'/num_facilities_end
	}
 
* d.2. Rescale variables to thousands
  local vars ///
  c5_swemerge_start ///
  c6_swapstgraded_start c6_swnpstgraded_start c6_swhosptadm_start /// 
  c6_swresearexp_start median_income_start tot_vol_start ///
  c5_swemerge_end ///
  c6_swapstgraded_end c6_swnpstgraded_end c6_swhosptadm_end ///
  c6_swresearexp_end median_income_end tot_vol_end
  
  foreach x of var `vars' { 
	replace `x' = `x'/1000
	}


* d.2. Rescale specific variables to millions of dollars
  local vars_ ///
	c2_tot_margin_start c5_swtotals_start ///
	c2_tot_margin_end c5_swtotals_end 
  foreach x of var `vars_' { 
	replace `x' = `x'/1000000
	}
	
	
* d.3. Create per FTE variables
  gen c5_swfte_emerge_start= c5_swemerge_start/c5_fteemerge_start
  gen c5_swfte_totals_start= c5_swtotals_start/c5_ftetotals_start
  gen c6_swfte_apstgraded_start= c6_swapstgraded_start/c6_fteapstgraded_start
  gen c6_swfte_npstgraded_start= c6_swnpstgraded_start/c6_ftenpstgraded_start
  gen c6_swfte_hosptadm_start= c6_swhosptadm_start/c6_ftehosptadm_start
  gen c6_swfte_researexp_start= c6_swresearexp_start/c6_fteresearexp_start
  
  gen c5_swfte_emerge_end= c5_swemerge_end/c5_fteemerge_end
  gen c5_swfte_totals_end= c5_swtotals_end/c5_ftetotals_end
  gen c6_swfte_apstgraded_end= c6_swapstgraded_end/c6_fteapstgraded_end
  gen c6_swfte_npstgraded_end= c6_swnpstgraded_end/c6_ftenpstgraded_end
  gen c6_swfte_hosptadm_end= c6_swhosptadm_end/c6_ftehosptadm_end
  gen c6_swfte_researexp_end= c6_swresearexp_end/c6_fteresearexp_end
  
  drop c5_fteemerge_start c5_ftetotals_start c6_fteresearexp_start ///
  c6_fteapstgraded_start c6_ftenpstgraded_start c6_ftehosptadm_start ///
  c5_fteemerge_end c5_ftetotals_end c6_fteresearexp_end ///
  c6_fteapstgraded_end c6_ftenpstgraded_end c6_ftehosptadm_end
        

  
* 4. save  
  if `j' == $latest_start {
	compress
	save ${merged}merged_ED_physicians_2006_to_`lastest_start_year'.dta, replace
	}
	else {
		compress
		append using ${merged}merged_ED_physicians_2006_to_`lastest_start_year'.dta, force
		sort start_year 
		drop if missing(start_year)
		save ${merged}merged_ED_physicians_2006_to_`lastest_start_year'.dta, replace
		}
  restore
}


*===========================================================================
* 3. Remove edited financial data
*===========================================================================

  forvalues j=2005/2020 {
erase ${merged}FL_EDs_neighbor_finance_`j'_edited.dta
  }
  
erase ${merged}predicted_pe_edited.dta


 

*===========================================================================
* 4. Merge in salaries data   
*===========================================================================

* 1. Load dataset 
  use ${merged}merged_ED_physicians_2006_to_2014.dta, clear

* 2. Merge

  // **Start year
  rename zip_start postal_code
  merge m:1 postal_code using ${merged}H1B_Perm_per_zipcode_salary.dta
   // Assess merge
  tab _merge
  tab postal_code if _merge==1
  drop if _merge==2
  drop _merge
  // Rename variables with prefix s_ for start year
  foreach e of varlist pw_median-pw_95th {
  rename `e' `e'_start
  }  
  rename postal_code zip_start
  
  // **End year   
  rename zip_end postal_code
  merge m:1 postal_code using ${merged}H1B_Perm_per_zipcode_salary.dta
   // Assess merge
  tab _merge
  tab postal_code if _merge==1
  drop if _merge==2
  drop _merge
  // Rename variables with prefix s_ for start year
  foreach e of varlist pw_median-pw_95th {
  rename `e' `e'_end
  }  
  rename postal_code zip_end

  
* 3. Rescale variables to thousands of dollars   
  replace pw_median_start = pw_median_start/1000
  replace pw_mean_start = pw_mean_start/1000
  replace pw_95th_start = pw_95th_start/1000

  replace pw_median_end = pw_median_end/1000
  replace pw_mean_end = pw_mean_end/1000
  replace pw_95th_end = pw_95th_end/1000
  
  
* 4. Save  
   save ${merged}merged_ED_physicians_2006_to_2014.dta, replace  

 
*===========================================================================
* 4. Check pairwise correlations
*===========================================================================
 
 
 use ${financial}FL_EDs_neighbor_finance_2010.dta, clear
 pwcorr c5_swtotals b4_numbphys b4_physemer c2_tot_margin

 estpost correlate c5_swtotals b4_numbphys b4_physemer c2_tot_margin, ///
 matrix listwise
 esttab using ${results}corr_table1.tex, replace unstack not noobs ///
 nonote b(2) label

  
 
*===========================================================================
* 5. Run logit analysis
*===========================================================================


* 1. Load dataset 
  use ${merged}merged_ED_physicians_2006_to_2014.dta, clear
  gen cohort = start_year


* 2. Labeling
  label var median_income_start "Median income in tract (thousands)"
  label var num_EDs_start "Number of EDs"
  label var tot_vol_start "Work Volume (thousands)"
  label var b4_physemer_start "Number of EM Physicians (b4)"
  label var b4_numbphys_start "Total Number of Physicians (b4)"
  label var c2_tot_margin_start "Hospital net Revenue (c2) (Millions)"
  label var c5_swtotals_start "Hospital salaries expense (c5) (Millions)"
  
  
* 4. STEP1: Overall physician attrition 
/*
Predict whether physicians Leave practice in FL 6 years after their start year.
-> regular logit as a function of the initial hospital's characteristics 
*/  

// Dependent variable
  gen leave_end = (work_end==0)
   
//   eststo logit1: logit switch_end ptsday_start ib(2006).cohort, robust
  logit leave_end ptsday_start ib(2006).cohort, robust
  eststo margin: margins, dydx(*) post
  est sto logit1
  
  logit leave_end median_income_start ib(2006).cohort, robust
  eststo margin: margins, dydx(*) post
  est sto logit2
  
  logit leave_end num_EDs_start ib(2006).cohort, robust
  eststo margin: margins, dydx(*) post
  est sto logit3 
  
  logit leave_end tot_vol_start ib(2006).cohort, robust
  eststo margin: margins, dydx(*) post
  est sto logit4 
  
  logit leave_end ptsday_start median_income_start ///
  num_EDs_start tot_vol_start ib(2006).cohort, robust
  eststo margin: margins, dydx(*) post
  est sto logit1_4 
  
  
  logit leave_end b4_physemer_start ib(2006).cohort, robust
  eststo margin: margins, dydx(*) post
  est sto logit5 
  
  logit leave_end b4_numbphys_start ib(2006).cohort, robust
  eststo margin: margins, dydx(*) post
  est sto logit6
  
  logit leave_end c2_tot_margin_start ib(2006).cohort, robust
  eststo margin: margins, dydx(*) post
  est sto logit7
  
  logit leave_end c5_swtotals_start ib(2006).cohort, robust
  eststo margin: margins, dydx(*) post
  est sto logit8
  
  logit leave_end b4_physemer_start b4_numbphys_start ///
  c2_tot_margin_start c5_swtotals_start ib(2006).cohort, robust
  eststo margin: margins, dydx(*) post
  est sto logit5_8
  
  
  * Table 1 
  esttab logit1 logit2 logit3 logit4 logit1_4 ///
  using ${results}logit_estimates_1.tex, label ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  indicate("Cohort Fixed-Effects = *.cohort") ///
  alignment(D{.}{.}{-1}) mtitles() /// 
  title("Marginal effects - Overall relocation out of FL for 9 cohorts of ED physicians between 2006 and 2020") replace
 
  * Table 2 
  esttab logit5 logit6 logit7 logit8 logit5_8 ///
  using ${results}logit_estimates_2.tex, label ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  indicate("Cohort Fixed-Effects = *.cohort") ///
  alignment(D{.}{.}{-1}) mtitles() /// 
  title("Marginal effects - Overall relocation out of FL for 9 cohorts of ED physicians between 2006 and 2020") replace

 
/*  
*===============================================================================
* 4. Set up model for cmclogit
*===============================================================================

* 1. Load dataset 
  use ${merged}merged_ED_physicians_2006_to_2014.dta, clear
  
* 2.conditional logit setup: CREATE VARIABLES
    
  // A. Choice variable
  tabulate end_LICENSENUMBER, generate(choice)  
/*
For the next stepts, see explanation @ statalist: How to give all cells of one column the same value that is currently in only one cell? (within group)
*/  
  // B. Hospital revenue variable 
  forvalues x= 1/181 {
  	generate hosp_revenue`x'= end_c2_tot_margin*choice`x'
	bysort start_year (hosp_revenue`x'): ///
	replace hosp_revenue`x'=hosp_revenue`x'[_N] if hosp_revenue`x'==0
  }  
  // C. Emergency Services salaries 
  forvalues x= 1/181 {
  	generate ed_salary`x'= end_c5_swemerge*choice`x'
	bysort start_year (ed_salary`x'): ///
	replace ed_salary`x'=ed_salary`x'[_N] if ed_salary`x'==0
  }  
  // D.  Research Expense salaries 
  forvalues x= 1/181 {
  	generate res_salary`x'= end_c6_swresearexp *choice`x'
	bysort start_year (res_salary`x'): ///
	replace res_salary`x'=res_salary`x'[_N] if res_salary`x'==0	
  } 
  
  //E. Number of facilities under the license number
   forvalues x= 1/181 {
  	generate nfacilities`x'= end_num_facilities*choice`x'
	bysort start_year (nfacilities`x'): ///
	replace nfacilities`x'=nfacilities`x'[_N] if nfacilities`x'==0
  } 
  
   //F. Staffing ratio
   forvalues x= 1/181 {
  	generate patientspday`x'= end_ptsday*choice`x'
	bysort start_year (patientspday`x'): ///
	replace patientspday`x'=patientspday`x'[_N] if patientspday`x'==0
  } 
  
    //G. Employee benefits
   forvalues x= 1/181 {
  	generate empbenefits`x'= end_benefits_per_FTE*choice`x'
	bysort start_year (empbenefits`x'): ///
	replace empbenefits`x'=empbenefits`x'[_N] if empbenefits`x'==0
  } 
  
* 3.conditional logit setup: RESHAPE
  drop if attenphyid ==""
  gen id = _n // ID variable
  order id 
  sort start_year
  reshape long choice hosp_revenue ed_salary res_salary nfacilities ///
  empbenefits patientspday, i(id) j(alternative)
  keep id attenphyid end_LICENSENUMBER alternative choice hosp_revenue ///
  ed_salary res_salary patientspday empbenefits nfacilities ///
  ed_faclnbr1_start vol_per_ED1_start start_c2_tot_margin ///
  start_c5_swemerge start_c6_swresearexp 
  order id attenphyid end_LICENSENUMBER alternative choice hosp_revenue ///
  ed_salary res_salary patientspday empbenefits nfacilities ///
  ed_faclnbr1_start vol_per_ED1_start start_c2_tot_margin ///
  start_c5_swemerge start_c6_swresearexp 

  
*4.Save
  compress
  save ${merged}cmclogit_ED_physicians_2008_to_2014.dta, replace
  clear
  


*===============================================================================
* 6. Run cmclogit analysis
*===============================================================================

* 1. Load 
  use ${merged}cmclogit_ED_physicians_2008_to_2014.dta, clear

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

