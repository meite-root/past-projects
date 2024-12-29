/*========================================================================
Title: 6_Analysis_1_attrition.do
Author: Hassane Meite
Date created: Tue 4 Apr 2023
Date last updated: Tue 4 Apr 2023
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
  log using ${code}6_Analysis_attrition.log, replace
  display c(current_time) 
  
  
  
*=========================================================================
* Model 1: Survival analysis - Overall physician attrition 
*=========================================================================

/*
Predict whether physicians Leave practice in FL the next year
-> regular logit as a function of the current hospital's characteristics 
*/  

/* https://statisticsbyjim.com/probability/hazard-ratio/
Event: whether physicians Leave practice in FL:
**Using many time points allows the analysis to include data from subjects who drop out partway through or do not reach a study’s defined endpoint**


-The survival Function at time t, denoted S(t), is the probability of being 
event-free at t; 
-Display the proportion of subjects who have not experienced an event (Y-axis) by time intervals (X-axis). 

-> Equivalently, the probability (P) that the survival time is greater than t. 
-> Equivalently, The event probability (1-P) over time (<t), which analysts refer to as the hazard rates
--> A hazard ratio is the ratio of two hazard rates: treatment Vs control

Hazard Ratio = 1: An HR equals one when the numerator and denominator are equal. This equivalence occurs when both groups experience the same number of events in a period.

Hazard Ratio > 1: The numerator is greater than the denominator in the hazard ratio. Therefore, the treatment group experiences a higher event probability within any given period than the control group.

Hazard Ratio < 1: The numerator is less than the denominator in the HR. Consequently, the treatment group experiences a lower event probability during a unit of time than the control group.

*/
/*
Physician attrition - related variables 

-> Physician 
var1*: ptsday "Patients per day"
var2: pe "Private equity contract"
var3***: tot_vol "Total work volume"
var4***: vol_per_ED "Work volume per practice ED"
var5***: num_EDs "Number of EDs physician works in"

-> Hospital: staff in numbers
var6*: c5_ftetotals "Total No. of employees"
var7: c6_ftehosptadm "Total No. of admin staff"
var8: b4_numbphys "Total Number of physicians - Health Ed. Prorgams"
var9: b4_physemer "Number of EM physicians - Health Ed. Prorgams"
var10: b4xtra_physemer_approved "Approved program - EM (y/n)"

-> Hospital: expenses
var11: c6_swhosptadm "c6 - Salary expense - Hospital Admin." 
var12: c6_swfte_hosptadm "c6 - Salaries expense per FTE - H. Admin."

-> Tract level
var13: total_population "Estimate Total population per tract" 
var14: poverty "Poverty rate per tract"
var15: house_value "Median house value per tract"
var16: ru2003 "2003 Rural-Urban Continuum Code"
*/

* 1. Load dataset 
  use ${merged}EM_physician_years_2006_to_2020.dta, clear
 
* 2. drop 2020 observations: cannot be observed the following year
  drop if year ==2020  
  
* 3. New variables 
  // Physician: Work volume
  gen ptsday_binary = (ptsday >= 15)
  label var ptsday_binary "Over 15 Patients per day"
  gen ptsday_binary_top = (ptsday >= 30)
  label var ptsday_binary_top "Over 30 Patients per day"
  gen ptsday_binary_low = (ptsday <= 5)
  label var ptsday_binary_low "Less than 5 Patients per day"
  gen ptsday_10 = (ptsday/10)
  label var ptsday_10 "Patients per day (10s)"
  xtile quart = ptsday, nq(4)
  gen ptsday_q1 = (quart==1)
  gen ptsday_q4 = (quart==4)
  drop quart
  label var ptsday_10 "Patients per day (10s)"
  gen tot_vol_binary = (tot_vol>=3.5)
  label var tot_vol_binary "Over 3500 Patients in year"
  gen num_EDs_binary = (num_EDs>3)
  label var num_EDs_binary "Over 4 EDs at a time"
  gen vol_per_ED_binary = (vol_per_ED>=3000)
  label var vol_per_ED_binary "Over 3000 Patients per ED in year"
  // hospital: Number, staff
  gen c5_ftetotals_binary = (c5_ftetotals >=550)
  label var c5_ftetotals_binary "Over 550 total staff in location"
  gen c6_ftehosptadm_binary = (c6_ftehosptadm >=65)
  label var c6_ftehosptadm_binary "Over 65 Admin staff in location"
  gen b4_numbphys_binary = (b4_numbphys>=270)
  label var b4_numbphys_binary "Over 270 physicians in location - Health Ed."
  gen b4_physemer_binary = (b4_physemer>=18)
  label var b4_physemer_binary "Over 18 EM physicians in location - Health Ed."  
  // hospital: Expenses
  gen c6_swhosptadm_binary = (c6_swhosptadm>=5.5)
  label var c6_swhosptadm_binary "Over 5.5M in admin expenses"
  gen c6_swfte_hosptadm_binary = (c6_swfte_hosptadm>=110)
  label var c6_swfte_hosptadm_binary "Over 110k per FTE in admin expenses"
  gen adminexp_share = 100*c6_swhosptadm/c5_swtotals
  gen adminexp_share_binary = (adminexp_share>=11)
  label var adminexp_share_binary "Admin expenses over 11pct of total"
  // Tract
  gen total_population_binary = (total_population>=6.5)
  label var total_population_binary "Population in tract over 6500"
  gen poverty_binary = (poverty>=40)
  label var poverty_binary "Over 40 percent poverty in tract"
  gen house_value_binary = (house_value>=275)
  label var house_value_binary "Median house value in tract over 275k"
  gen non_metro = (ru2003 >= 4)
  label var non_metro "Hospital located in non_metro area"
  
* 4. Declare data to be survival-time  
  gen t_years= experience+1
  order attenphyid attenphynpi attenphyid_e t_years
  stset t_years, id(attenphyid_e) failure(leave_FL)

* 5. Kaplan-Meir Curves
  sts graph,
  sts graph, by(ptsday_binary)
  // stphplot, by(ptsday_binary)

* 6. Regressions
  
  // individual
  eststo hr_1: stcox ptsday_binary
  eststo hr_2: stcox pe
  eststo hr_3: stcox tot_vol_binary
  eststo hr_4: stcox num_EDs_binary
  eststo hr_5: stcox vol_per_ED_binary
  
  eststo hr_6: stcox c5_ftetotals_binary
  eststo hr_7: stcox c6_ftehosptadm_binary
  eststo hr_8: stcox b4_numbphys_binary
  eststo hr_9: stcox b4_physemer_binary
  eststo hr_10: stcox b4xtra_physemer_approved

  eststo hr_11: stcox c6_swhosptadm_binary
  eststo hr_12: stcox c6_swfte_hosptadm_binary
  
  eststo hr_13: stcox total_population_binary
  eststo hr_14: stcox poverty_binary
  eststo hr_15: stcox house_value_binary
  eststo hr_16: stcox non_metro
  
  // Multiple - Main table v1
  eststo main_1:stcox ptsday pe tot_vol_binary num_EDs_binary
  eststo main_2:stcox ptsday pe tot_vol_binary num_EDs_binary ///
  b4_numbphys_binary b4xtra_physemer_approved
  eststo main_3a:stcox ptsday pe tot_vol_binary num_EDs_binary ///
		 b4_numbphys_binary b4xtra_physemer_approved ///
		 c6_swfte_hosptadm_binary
  eststo main_3b:stcox ptsday pe tot_vol_binary num_EDs_binary ///
		 b4_numbphys_binary b4xtra_physemer_approved ///
		 adminexp_share_binary
  eststo main_4:stcox ptsday pe tot_vol_binary num_EDs_binary ///
		 b4_numbphys_binary b4xtra_physemer_approved ///
		 c6_swfte_hosptadm_binary ///
		 poverty_binary non_metro
		 
  // Multiple - Main table v2 <- used in paper
  eststo main2_1:stcox ptsday_binary_top ptsday_binary_low pe tot_vol_binary num_EDs_binary
  eststo main2_2:stcox ptsday_binary_top ptsday_binary_low pe tot_vol_binary num_EDs_binary ///
  b4_numbphys_binary b4xtra_physemer_approved
  eststo main2_3a:stcox ptsday_binary_top ptsday_binary_low pe tot_vol_binary num_EDs_binary ///
		 b4_numbphys_binary b4xtra_physemer_approved ///
		 c6_swfte_hosptadm_binary
  eststo main2_3b:stcox ptsday_binary_top ptsday_binary_low pe tot_vol_binary num_EDs_binary ///
		 b4_numbphys_binary b4xtra_physemer_approved ///
		 adminexp_share_binary
  eststo main2_4:stcox ptsday_binary_top ptsday_binary_low pe tot_vol_binary num_EDs_binary ///
		 b4_numbphys_binary b4xtra_physemer_approved ///
		 c6_swfte_hosptadm_binary ///
		 poverty_binary non_metro		 

  // Multiple 2 - Main table v3 <- used in paper
  eststo main3_1:stcox ptsday pe tot_vol num_EDs
  eststo main3_2:stcox ptsday pe tot_vol num_EDs ///
  b4_numbphys b4xtra_physemer_approved
  eststo main3_3a:stcox ptsday pe tot_vol num_EDs ///
		 b4_numbphys b4xtra_physemer_approved ///
		 c6_swfte_hosptadm
  eststo main3_3b:stcox ptsday pe tot_vol num_EDs ///
		 b4_numbphys b4xtra_physemer_approved ///
		 adminexp_share
   eststo main3_4:stcox ptsday pe tot_vol num_EDs ///
		 b4_numbphys b4xtra_physemer_approved ///
		 c6_swfte_hosptadm ///
		 poverty ru2003
		 
  // Multiple 2 - Main table v4
  eststo main4_1:stcox ptsday_binary_top ptsday_binary_low pe tot_vol num_EDs
  eststo main4_2:stcox ptsday_binary_top ptsday_binary_low pe tot_vol num_EDs ///
  b4_numbphys b4xtra_physemer_approved
  eststo main4_3a:stcox ptsday_binary_top ptsday_binary_low pe tot_vol num_EDs ///
		 b4_numbphys b4xtra_physemer_approved ///
		 c6_swfte_hosptadm
  eststo main4_3b:stcox ptsday_binary_top ptsday_binary_low pe tot_vol num_EDs ///
		 b4_numbphys b4xtra_physemer_approved ///
		 adminexp_share
   eststo main4_4:stcox ptsday_binary_top ptsday_binary_low pe tot_vol num_EDs ///
		 b4_numbphys b4xtra_physemer_approved ///
		 c6_swfte_hosptadm ///
		 poverty ru2003		 
	
 
 
  * Main Table 1
  esttab main_1 main_2 main_3a main_3b main_4 ///
  using ${results}hazard_ratios_1_main.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) ///
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) /// 
  title("Hazard Ratios - Overall physician attrition out of Florida between 2006 and 2020") replace

  * Main Table 2
  esttab main2_1 main2_2 main2_3a main2_3b main2_4 ///
  using ${results}hazard_ratios_2_main.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) ///
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) /// 
  title("Hazard Ratios - Overall physician attrition out of Florida between 2006 and 2020") replace
 
  * Main Table 3
  esttab main3_1 main3_2 main3_3a main3_3b main3_4 ///
  using ${results}hazard_ratios_3_main.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) ///
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) /// 
  title("Hazard Ratios - Overall physician attrition out of Florida between 2006 and 2020") replace
 
  * Main Table 4
  esttab main4_1 main4_2 main4_3a main4_3b main4_4 ///
  using ${results}hazard_ratios_4_main.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) ///
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) /// 
  title("Hazard Ratios - Overall physician attrition out of Florida between 2006 and 2020") replace
  

  * Appendix Table 1: Work volume -
  esttab hr_1 hr_2 hr_3 hr_4 hr_5 ///
  using ${results}hazard_ratios_appendix_1.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) ///
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) /// 
  title("Hazard Ratios - Work volume: Overall physician attrition out of Florida between 2006 and 2020") replace
  
  * Appendix Table 2: Hospital Staff
  esttab hr_6 hr_7 hr_8 hr_9 hr_10 ///
  using ${results}hazard_ratios_appendix_2.tex, eform label ///
  mtitles("Model 6" "Model 7" "Model 8" "Model 9" "Model 10") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) ///
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) /// 
  title("Hazard Ratios - Hospital Staff: Overall physician attrition out of Florida between 2006 and 2020") replace
 
 
  * Appendix Table 3: Hospital Expenditure
  esttab hr_11 hr_12 ///
  using ${results}hazard_ratios_appendix_3.tex, eform label ///
  mtitles("Model 11" "Model 12") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) ///
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) /// 
  title("Hazard Ratios - Hospital Expenditure: Overall physician attrition out of Florida between 2006 and 2020") replace
 
 
  * Appendix Table 4: Tract level 
 esttab hr_13 hr_14 hr_15 hr_16 ///
  using ${results}hazard_ratios_appendix_4.tex, eform label ///
  mtitles("Model 13" "Model 14" "Model 15" "Model 16") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) ///
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) /// 
  title("Hazard Ratios - Tract level: Overall physician attrition out of Florida between 2006 and 2020") replace

  
  
  
  
/*
	
  // Multiple - Main table v2 <- used in paper
  eststo main2_1:stcox ptsday_binary_top ptsday_binary_low pe tot_vol_binary num_EDs_binary, vce(cluster year)
  eststo main2_2:stcox ptsday_binary_top ptsday_binary_low pe tot_vol_binary num_EDs_binary b4_numbphys_binary b4xtra_physemer_approved, vce(cluster year)
  eststo main2_3a:stcox ptsday_binary_top ptsday_binary_low pe tot_vol_binary num_EDs_binary b4_numbphys_binary b4xtra_physemer_approved c6_swfte_hosptadm_binary, vce(cluster year)
  eststo main2_3b:stcox ptsday_binary_top ptsday_binary_low pe tot_vol_binary num_EDs_binary b4_numbphys_binary b4xtra_physemer_approved adminexp_share_binary, vce(cluster year)
  eststo main2_4:stcox ptsday_binary_top ptsday_binary_low pe tot_vol_binary num_EDs_binary b4_numbphys_binary b4xtra_physemer_approved c6_swfte_hosptadm_binary poverty_binary non_metro, vce(cluster year)		 

 * Main Table 2
  esttab main2_1 main2_2 main2_3a main2_3b main2_4 using ${results}hazard_ratios_2vce_main.tex, eform label mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) labels("\$Pseudo R^2\$" "\$N\$")) alignment(D{.}{.}{-1}) title("Hazard Ratios - Overall physician attrition out of Florida between 2006 and 2020") replace
 
 
  // Multiple 2 - Main table v3 <- used in paper
  eststo main3_1:stcox ptsday pe tot_vol num_EDs, vce(cluster year)
  eststo main3_2:stcox ptsday pe tot_vol num_EDs b4_numbphys b4xtra_physemer_approved, vce(cluster year)
  eststo main3_3a:stcox ptsday pe tot_vol num_EDs b4_numbphys b4xtra_physemer_approved c6_swfte_hosptadm, vce(cluster year)
  eststo main3_3b:stcox ptsday pe tot_vol num_EDs b4_numbphys b4xtra_physemer_approved adminexp_share, vce(cluster year)
  eststo main3_4:stcox ptsday pe tot_vol num_EDs b4_numbphys b4xtra_physemer_approved c6_swfte_hosptadm poverty ru2003, vce(cluster year)
		
 
  * Main Table 3
  esttab main3_1 main3_2 main3_3a main3_3b main3_4 using ${results}hazard_ratios_3vce_main.tex, eform label mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) labels("\$Pseudo R^2\$" "\$N\$")) alignment(D{.}{.}{-1}) title("Hazard Ratios - Overall physician attrition out of Florida between 2006 and 2020") replace
 
 */
 
