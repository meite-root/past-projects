/*==============================================================================
Title: 4_Summary_stats.do
Author: Hassane Meite
Date created: Sun 10 April
Date last updated: Mon 9 May
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
  global edphys "/data/jv947/Lab_Shared/ED_claims/phys_cohorts/"

* Set folder subdirectories
  global code "${path}/code/Hassane/"
  global data "${path}/FL_Hospital_Financial_Data/all_raw/"
  global merged "${path}/FL_Hospital_Financial_Data/stata/"
  global sheets "${path}/FL_Hospital_Financial_Data/stata/sheets/"
  global results "${path}/results/Hassane/"

* Initialize log
  log using ${code}4_Summary_stats.log, replace
  display c(current_time) 
  

*===============================================================================
* 1. EM attending physicians - Cohort 2013/2019
*===============================================================================

* Load dataset on EM attending physicians
  use "${edphys}all_ED_physicians_2013_to_2019.dta", clear
  describe

* Check for missing data  
  tab attenphynpi_2013 , missing
  tab attenphynpi_2019 , missing
  tab vol_tot_2013 , missing
  tab vol_tot_2019 , missing
  
  /*
  284 physicians (rows) in the cohort 
  For each physician, 2013 and 2019 worksites are listed, ordered by work
  volume
  51 obseravtions have missing hours worked data for 2019
  */

  
*===============================================================================  
* 2. Summary Statistics - ED physicians
*===============================================================================

  eststo not_working: quietly estpost summarize ///
		num_EDs_2013 num_EDs_2019 vol_tot_2013 vol_tot_2019 if work2019 ==0
  eststo still working: quietly estpost summarize ///
		num_EDs_2013 num_EDs_2019 vol_tot_2013 vol_tot_2019 if work2019 == 1

  esttab still_working not_working using ${results}summary_stats_EDphys.tex, ///
  cells ("mean (pattern (1 1 0) fmt (0)) sd (pattern (1 1 0) fmt (0)) min max") ///
  titles ("Still working in Florida in 2019" "No longer working in Florida in 2019") ///
  label replace

  
*===============================================================================  
* 3. Summary Statistics - ED physicians
*===============================================================================

  eststo all: quietly estpost summarize ///
	a2_ed_inhous a2_ed_oncall c2_tot_oper_rev ///
	c2_tot_oper_cost c5_swemerge c6_swresearexp

  esttab all using ${results}summary_stats_Hospitals.tex, ///
  cells ("mean (pattern (1 1 0) fmt (0)) sd (pattern (1 1 0) fmt (0)) min max") ///
  label replace
  
  
*===============================================================================
* 4. Graphs
*===============================================================================

* Graph 1: Total numbers of hours of work in 2013 Vs in 2019  
  clear
  use ${edphys}all_ED_physicians_2013_to_2019.dta
  collapse (sum) vol_tot_2013 (sum) vol_tot_2019
  graph bar vol_tot_2013 vol_tot_2019, ///
  legend(order(1 "Hours worked in 2013 " 2 "Hours worked in 2019" ))
  graph export ${results}a1.ED_physicians_totalhours.png, as(png) replace
  
  // More hours worked in 2019 in total.

* Graph 2: Spread of number of EDs in which Doctors work in 2013 Vs in 2019  
  clear
  use ${edphys}all_ED_physicians_2013_to_2019.dta
  twoway ///
	(histogram num_EDs_2013, width(1) color(green%30)) ///        
	(histogram num_EDs_2019, width(1) color(red%30)), /// 
	title("Spread of number of EDs in which Physicians worked") ///
	subtitle("2013 Versus 2019") ///
	legend(order(1 "2013" 2 "2019" )) name(figure1, replace)
  graph export ${results}a2.ED_physicians_spread.png, as(png) replace

  /*
   Larger spread in 2019 than in 2013
   Few ED physicians work in just one facility in 2019. More work in
   multiple facilities.
  */
 
* Graph 3: Distribution of the pct of 2013 EDs the cohort's in 2019 EDs   
  clear
  use ${edphys}all_ED_physicians_2013_to_2019.dta
  twoway ///
	(histogram pct_same_EDs , width(8) fcolor(gold%30) lcolor(gold)), ///
	title("Distribution of the pct of 2013 EDs the cohort's in 2019 EDs")
  graph export ${results}a3.ED_physicians_pct_same_EDs.png, as(png) replace


