/*========================================================================
Title: 6_Analysis_relocation.do
Author: Hassane Meite
Date created: Tue 4 April
Date last updated: Tue 4 April
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
  log using ${code}6_Analysis_relocation.log, replace
  display c(current_time) 
  
    
  
*========================================================================
* Logit - ODDS ratios: Physician relocation within Florida
*========================================================================

/*
Predict Physician relocation over time, using ODDS ratios
^ Each regression using calendar year dummies, then year dummies
*/ 


/*
Physician relocation - related variables 

-> Physician (Control variables)
var1: ptsday "Patients per day"
var2: pe "Private equity contract"
var3: tot_vol "Total work volume (ks)"
var4: num_EDs "Number of EDs physician works in"
var5: *experience

-> Wages
var6: pw_median "Zip Code Prevailing wage median (ks)"
var7: pw_mean "Zip Code Prevailing wage mean (ks)"
var8: pw_95th "Zip Code Prevailing wage 95th perc. (ks)"
var9: benefits_per_FTE "Benefits per full time employee"

-> Hospital: staff in numbers
var10: c5_ftetotals "Total No. of employees"
var11: c5_fteemerge " c5 - No. of FTE - Emergency Services"
var12: c6_ftehosptadm "Total No. of admin staff"
var13: b4_numbphys "Total Number of physicians - Health Ed. Prorgams"
var14: b4_physemer "Number of EM physicians - Health Ed. Prorgams"
var15: b4xtra_physemer_approved "Approved program - EM (y/n)"

-> Hospital: Financial standing
var16: c2_tot_margin "c2 - Hospital net Revenue (Ms)"
var17: c5_swfte_emerge "c5 - Salary expense per FTE - Em. S"
var18: c6_swresearexp "c6 - Salary expense - research (ks)"
var19: c5_swfte_totals "c5 - Salaries expense per FTE - Total"
var20: c6_swfte_hosptadm "c6 - Salaries expense per FTE - H. Admin."

-> Tract level
var21: total_population "Estimate Total population per tract"
var22: median_income "Total Median Income per tract (ks)" 
var23: poverty "Poverty rate per tract"
var24: house_value "Median house value per tract"
var25: ru2003 "2003 Rural-Urban Continuum Code"
*/


* 1. Load dataset 
  use ${merged}EM_physician_years_2006_to_2020.dta, clear
  // Drop last observations: Cannot be observed the following year
  drop if year == 2020  
  drop if leave_FL == 1

* 2. New variables: Difference between current and next year
  
  // New
  gen ptsday_binary = (ptsday >= 15)
  gen ptsday_binary_top = (ptsday >= 30) 
  gen non_metro = (ru2003 >= 4)
  gen poverty_binary = (poverty>=40)
  label var ptsday_binary_top "Over 30 Patients per day"
  label var ptsday_binary "Over 15 Patients per day"
  label var non_metro "Hospital located in non_metro area"
  label var poverty_binary "Over 40 percent poverty in tract"
  gen adminexp_share = 10*c6_swhosptadm/c5_swtotals
  label var adminexp_share "Admin expenses over of total (10pct)"
  
  // New new
  replace c5_swfte_totals = c5_swfte_totals/10
  label var c5_swfte_totals "Salaries expense per FTE - Total (10ks)"
  replace b4_numbphys =b4_numbphys/10 
  label var b4_numbphys "Total No. of physicians - Health Ed. (Tens)"
  replace pw_median = pw_median/10
  label var pw_median "Zip Code Prevailing wage median (10ks)"

* 3. Declare Panel dataset
  xtset attenphyid_e year

  
* 4. Regressions  

**** INDIVIDUAL  
  * Experience/year
  eststo odds_0: logit relocate_FL ib(0).experience, or
  eststo odds_0y: logit relocate_FL ib(2006).year, or

  * Physician
  //1  
  eststo odds_1: logit relocate_FL ptsday_binary ib(0).experience, or
  eststo odds_1y: logit relocate_FL ptsday_binary ib(2006).year, or
  
  //2
  eststo odds_2: logit relocate_FL tot_vol ib(0).experience, or
  eststo odds_2y: logit relocate_FL tot_vol ib(2006).year, or
  
  //3
  eststo odds_3: logit relocate_FL num_EDs ib(0).experience, or
  eststo odds_3y: logit relocate_FL num_EDs ib(2006).year, or
  
  //4
  eststo odds_4: logit relocate_FL non_metro ib(0).experience, or
  eststo odds_4y: logit relocate_FL non_metro ib(2006).year, or
  
  //5
  eststo odds_5: logit relocate_FL b4xtra_physemer_approved ib(0).experience, or
  eststo odds_5y: logit relocate_FL b4xtra_physemer_approved ib(2006).year, or
 
  //1_5
  eststo odds1_5: logit relocate_FL ptsday_binary pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved ib(0).experience, or
  eststo odds1_5y: logit relocate_FL ptsday_binary pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved ib(2006).year, or
  
  
  * Hospital Staffing
  //6
  eststo odds_6: logit relocate_FL c5_ftetotals ib(0).experience, or
  eststo odds_6y: logit relocate_FL c5_ftetotals ib(2006).year, or
  
  //7
  eststo odds_7: logit relocate_FL c5_fteemerge ib(0).experience, or
  eststo odds_7y: logit relocate_FL c5_fteemerge ib(2006).year, or
  
  //8
  eststo odds_8: logit relocate_FL c6_ftehosptadm ib(0).experience, or
  eststo odds_8y: logit relocate_FL c6_ftehosptadm ib(2006).year, or
  
  //9
  eststo odds_9: logit relocate_FL b4_numbphys ib(0).experience, or
  eststo odds_9y: logit relocate_FL b4_numbphys ib(2006).year, or
  
  //10
  eststo odds_10: logit relocate_FL b4_physemer ib(0).experience, or
  eststo odds_10y: logit relocate_FL b4_physemer ib(2006).year, or

  * Hospital: Financial standing  
  //11  
  eststo odds_11: logit relocate_FL c2_tot_margin ib(0).experience, or
  eststo odds_11y: logit relocate_FL c2_tot_margin ib(2006).year, or
  
  //12  
  eststo odds_12: logit relocate_FL c5_swfte_emerge ib(0).experience, or
  eststo odds_12y: logit relocate_FL c5_swfte_emerge ib(2006).year, or
  
  //13  
  eststo odds_13: logit relocate_FL c6_swresearexp ib(0).experience, or
  eststo odds_13y: logit relocate_FL c6_swresearexp ib(2006).year, or
  
  //14  
  eststo odds_14: logit relocate_FL c5_swfte_totals ib(0).experience, or
  eststo odds_14y: logit relocate_FL c5_swfte_totals ib(2006).year, or
  
  //15  
  eststo odds_15: logit relocate_FL c6_swfte_hosptadm ib(0).experience, or
  eststo odds_15y: logit relocate_FL c6_swfte_hosptadm ib(2006).year, or

  * Wages
  //16  
  eststo odds_16: logit relocate_FL pw_median ib(0).experience, or
  eststo odds_16y: logit relocate_FL pw_median ib(2006).year, or
  
  //17
  eststo odds_17: logit relocate_FL pw_mean ib(0).experience, or
  eststo odds_17y: logit relocate_FL pw_mean ib(2006).year, or
  
  //18 
  eststo odds_18: logit relocate_FL pw_95th ib(0).experience, or
  eststo odds_18y: logit relocate_FL pw_95th ib(2006).year, or
  
  //19 
  eststo odds_19: logit relocate_FL benefits_per_FTE ib(0).experience, or
  eststo odds_19y: logit relocate_FL benefits_per_FTE ib(2006).year, or

  
  * Tract level
  //20  
  eststo odds_20: logit relocate_FL total_population ///
  ib(0).experience, or
  eststo odds_20y: logit relocate_FL total_population ///
  ib(2006).year, or
  
  //21  
  eststo odds_21: logit relocate_FL median_income ib(0).experience, or
  eststo odds_21y: logit relocate_FL median_income ib(2006).year, or
  
  //22  
  eststo odds_22: logit relocate_FL poverty_binary ib(0).experience, or
  eststo odds_22y: logit relocate_FL poverty_binary ib(2006).year, or
  
  //23  
  eststo odds_23: logit relocate_FL house_value ib(0).experience, or
  eststo odds_23y: logit relocate_FL house_value ib(2006).year, or
  
  //24  
  eststo odds_24: logit relocate_FL ru2003 ib(0).experience, or
  eststo odds_24y: logit relocate_FL ru2003 ib(2006).year, or
  
  //20_24
  eststo odds20_24: logit relocate_FL total_population median_income ///
  poverty_binary house_value ru2003 ib(0).experience, or
  eststo odds20_24y: logit relocate_FL total_population median_income ///
  poverty_binary house_value ru2003 ib(2006).year, or
  

**** MULTIPLE  
  // Main table 1 
  eststo main_1: logit relocate_FL ptsday_binary_top pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved ib(0).experience, or
  eststo main_2: logit relocate_FL ptsday_binary_top pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved b4_numbphys ib(0).experience, or
  eststo main_3: logit relocate_FL ptsday_binary_top pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved b4_numbphys ///
  c5_swfte_totals adminexp_share ib(0).experience, or
  eststo main_4: logit relocate_FL ptsday_binary_top pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved b4_numbphys ///
  c5_swfte_totals adminexp_share pw_median ib(0).experience, or
  eststo main_5: logit relocate_FL ptsday_binary_top pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved b4_numbphys ///
  c5_swfte_totals adminexp_share pw_median total_population ///
  poverty_binary house_value ru2003 ib(0).experience, or
  
  
  
 **** MARGINAL EFFECTS
  // Main table 1
  logit relocate_FL ptsday_binary_top pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto main_1 
  
  logit relocate_FL ptsday_binary_top pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved b4_numbphys ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto main_2 
  
  logit relocate_FL ptsday_binary_top pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved b4_numbphys ///
  c5_swfte_totals adminexp_share ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto main_3 

  logit relocate_FL ptsday_binary_top pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved b4_numbphys ///
  c5_swfte_totals adminexp_share pw_median ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto main_4 

  logit relocate_FL ptsday_binary_top pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved b4_numbphys ///
  c5_swfte_totals adminexp_share pw_median total_population ///
  poverty_binary house_value ru2003 ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto main_5 
  
 
  // A - MAIN MARGINAL EFFECTS TABLE
  * Odds Main Table 1
  esttab main_1 main_2 main_3 main_4 main_5 ///
  using ${results}marginal_effects_1_main.tex, label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  indicate("Experience Fixed-Effects = *.experience") ///
  alignment(D{.}{.}{-1}) /// 
  title("marginal - Experience Fixed effects: Florida ED physicians' relocation patterns between 2006 and 2020") replace

 
* 5. Export Odds tables 

 // A - MAIN
  * Odds Main Table 1
  esttab main_1 main_2 main_3 main_4 main_5 ///
  using ${results}odds_ratios_1o_main.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  indicate("Experience Fixed-Effects = *.experience") ///
  alignment(D{.}{.}{-1}) /// 
  title("Odds Ratios - Experience Fixed effects: Florida ED physicians' relocation patterns between 2006 and 2020") replace
   
  // B - APPENDIX - EXPERIENCE FIXED EFFECTS 
  * Odds Table 1
  esttab odds_0 ///
  using ${results}odds_ratios_appendix_0.tex, eform label ///
  mtitles("Model 1") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) /// 
  title("Odds Ratios - Experience Fixed effects - Physician work volume: Florida ED physicians' relocation patterns between 2006 and 2020") replace
 
  * Odds Appendix Table 1: Physician Work Volume
  esttab odds_1 odds_2 odds_3 odds_4 odds_5 odds1_5 ///
  using ${results}odds_ratios_appendix_1.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  indicate("Experience Fixed-Effects = *.experience") ///
  alignment(D{.}{.}{-1}) /// 
  title("Odds Ratios - Experience Fixed effects - Physician work volume: Florida ED physicians' relocation patterns between 2006 and 2020") replace
 
  * Odds Appendix Table 2: Hospital Staffing 
  esttab odds_6 odds_7 odds_8 odds_9 odds_10 ///
  using ${results}odds_ratios_appendix_2.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  indicate("Experience Fixed-Effects = *.experience") ///
  alignment(D{.}{.}{-1}) /// 
  title("Odds Ratios - Experience Fixed effects - Hospital Staffing: Florida ED physicians' relocation patterns between 2006 and 2020") replace
 
  * Odds Appendix Table 3: Financial standing 
  esttab odds_11 odds_12 odds_13 odds_14 odds_15 ///
  using ${results}odds_ratios_appendix_3.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  indicate("Experience Fixed-Effects = *.experience") ///
  alignment(D{.}{.}{-1}) /// 
  title("Odds Ratios - Experience Fixed effects - Hospital Financial: standing Florida ED physicians' relocation patterns between 2006 and 2020") replace
  
  * Odds Appendix Table 4: Physician wages
  esttab odds_16 odds_17 odds_18 odds_19 ///
  using ${results}odds_ratios_appendix_4.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  indicate("Experience Fixed-Effects = *.experience") ///
  alignment(D{.}{.}{-1}) /// 
  title("Odds Ratios - Experience Fixed effects - Physician wages in zip code: standing Florida ED physicians' relocation patterns between 2006 and 2020") replace
 
  * Odds Appendix Table 4: Tract level
  esttab odds_20 odds_21 odds_22 odds_23 odds_24 odds20_24 ///
  using ${results}odds_ratios_appendix_5.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  indicate("Experience Fixed-Effects = *.experience") ///
  alignment(D{.}{.}{-1}) /// 
  title("Odds Ratios - Experience Fixed effects - Tract level variables: Florida ED physicians' relocation patterns between 2006 and 2020") replace
  
  // C - APPENDIX - YEAR FIXED EFFECTS 
  
   * Odds Table 0
  esttab odds_0y ///
  using ${results}odds_ratios_appendix_0y.tex, eform label ///
  mtitles("Model 1") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) /// 
  title("Odds Ratios - Year Fixed effects - Physician work volume: Florida ED physicians' relocation patterns between 2006 and 2020") replace
 

  * Odds Table 1 
  esttab odds_1y odds_2y odds_3y odds_4y odds_5y odds1_5y ///
  using ${results}odds_ratios_appendix_1y.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  indicate("Year Fixed-Effects = *.year") ///
  alignment(D{.}{.}{-1}) /// 
  title("Odds Ratios - Year Fixed effects - Physician work volume: Florida ED physicians' relocation patterns between 2006 and 2020") replace
 
  * Odds Table 2
  esttab odds_20y odds_21y odds_22y odds_23y odds_24y odds20_24y ///
  using ${results}odds_ratios_appendix_2y.tex, eform label ///
  mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5" "Model 6") ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  indicate("Year Fixed-Effects = *.year") ///
  alignment(D{.}{.}{-1}) /// 
  title("Odds Ratios - Year Fixed effects - Tract level variables: Florida ED physicians' relocation patterns between 2006 and 2020") replace
  
  
 /*
**** MULTIPLE  
  // Main table 1  <- Used in paper
  eststo main_1: logit relocate_FL ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved ib(0).experience, or
  eststo main_2: logit relocate_FL ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved b4_numbphys ib(0).experience, or
  eststo main_3: logit relocate_FL ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved b4_numbphys c5_swfte_totals adminexp_share ib(0).experience, or
  eststo main_4: logit relocate_FL ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved b4_numbphys c5_swfte_totals adminexp_share pw_median ib(0).experience, or
  eststo main_5: logit relocate_FL ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved b4_numbphys c5_swfte_totals adminexp_share pw_median poverty_binary ru2003 ib(0).experience, or
   
 // A - MAIN
  * Odds Main Table 1
  esttab main_1 main_2 main_3 main_4 main_5 using ${results}odds_ratios_1_main.tex, eform label mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) labels("\$Pseudo R^2\$" "\$N\$")) indicate("Experience Fixed-Effects = *.experience") alignment(D{.}{.}{-1}) title("Odds Ratios - Experience Fixed effects: Florida ED physicians' relocation patterns between 2006 and 2020") replace
  
  */
  
 
/* 

 **** MARGINAL EFFECTS    <- Used for paper
  
 
  logit relocate_FL ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto main_1 
  
  logit relocate_FL ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved b4_numbphys ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto main_2 
  
  logit relocate_FL ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved b4_numbphys  c5_swfte_totals adminexp_share ib(0).experience,
  eststo margin: margins, dydx(*) post
  est sto main_3 

  logit relocate_FL ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved b4_numbphys c5_swfte_totals adminexp_share pw_median ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto main_4 

  logit relocate_FL ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved b4_numbphys c5_swfte_totals adminexp_share pw_median poverty_binary ru2003 ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto main_5 
  
    // A - MAIN MARGINAL EFFECTS TABLE
  * Odds Main Table 1
  esttab main_1 main_2 main_3 main_4 main_5 using ${results}marginal_effects_1_main.tex, label mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) labels("\$Pseudo R^2\$" "\$N\$")) indicate("Experience Fixed-Effects = *.experience") alignment(D{.}{.}{-1}) title("marginal - Experience Fixed effects: Florida ED physicians' relocation patterns between 2006 and 2020") replace
   
  */
 
 
 
 
 
 
 
 
 
 /*
 
  .d8b.  d8888b.  .o88b. db   db d888888b db    db d88888b 
d8' `8b 88  `8D d8P  Y8 88   88   `88'   88    88 88'     
88ooo88 88oobY' 8P      88ooo88    88    Y8    8P 88ooooo 
88~~~88 88`8b   8b      88~~~88    88    `8b  d8' 88~~~~~ 
88   88 88 `88. Y8b  d8 88   88   .88.    `8bd8'  88.     
YP   YP 88   YD  `Y88P' YP   YP Y888888P    YP    Y88888P 

 */
 
 
 

 
*========================================================================
* 2. Logit - Marginal Effects: Physician relocation within Florida
*========================================================================



/*
Predict Physician relocation over time.

MODEL A
*regular logit as a function of hospital characteristics at time t
*Controlling for experience because it varies overtime 
*No multilevel modelling because there's no group effect 

MODEL B
Model A + Fixed effects: accounting for variables that are constant across individuals gender, or ethnicity,


MODEL C
Model A + differencing: independent variables are differences between current hospital's characteristics and future hospital location characteristics

ROTATIONS
^Do all of the above using calendar year dummies, then year dummies
*/  

/*
Physician relocation - related variables 

-> Physician (Control variables)
var1: ptsday "Patients per day"
var2: pe "Private equity contract"
var3: tot_vol "Total work volume (ks)"
var4: num_EDs "Number of EDs physician works in"
var5: *experience

-> Wages
var6: pw_median "Zip Code Prevailing wage median (ks)"
var7: pw_mean "Zip Code Prevailing wage mean (ks)"
var8: pw_95th "Zip Code Prevailing wage 95th perc. (ks)"
var9: benefits_per_FTE "Benefits per full time employee"

-> Hospital: staff in numbers
var10: c5_ftetotals "Total No. of employees"
var11: c5_fteemerge " c5 - No. of FTE - Emergency Services"
var12: c6_ftehosptadm "Total No. of admin staff"
var13: b4_numbphys "Total Number of physicians - Health Ed. Prorgams"
var14: b4_physemer "Number of EM physicians - Health Ed. Prorgams"
var15: b4xtra_physemer_approved "Approved program - EM (y/n)"

-> Hospital: Financial standing
var16: c2_tot_margin "c2 - Hospital net Revenue (Ms)"
var17: c5_swfte_emerge "c5 - Salary expense per FTE - Em. S"
var18: c6_swresearexp "c6 - Salary expense - research (ks)"
var19: c5_swfte_totals "c5 - Salaries expense per FTE - Total"
var20: c6_swfte_hosptadm "c6 - Salaries expense per FTE - H. Admin."

-> Tract level
var21: total_population "Estimate Total population per tract"
var22: median_income "Total Median Income per tract (ks)" 
var23: poverty "Poverty rate per tract"
var24: house_value "Median house value per tract"
var25: ru2003 "2003 Rural-Urban Continuum Code"

*/


* 1. Load dataset 
  use ${merged}EM_physician_years_2006_to_2020.dta, clear
 
* 2. New variables: Difference between current and next year
  
  // New
  gen ptsday_binary = (ptsday >= 15)
  gen non_metro = (ru2003 >= 4)
  gen poverty_binary = (poverty>=40)
  label var ptsday_binary "Over 15 Patients per day"
  label var non_metro "Hospital located in non_metro area"
  label var poverty_binary "Over 40 percent poverty in tract"

*3. Adjust for model C: differencing
  // Differences
/*  
  local list_vars ///
  ptsday pe tot_vol num_EDs ///
  pw_median pw_mean pw_95th benefits_per_FTE ///
  c5_ftetotals c5_fteemerge c6_ftehosptadm  ///
  b4_numbphys b4_physemer b4xtra_physemer_approved ///
  c2_tot_margin c5_swfte_totals c5_swfte_emerge ///
  c6_swresearexp c6_swfte_hosptadm ///
  total_population median_income house_value ru2003

  foreach x of var `list_vars' { 
  bysort attenphyid: replace `x' = `x'[_n+1] - `x'[_n]
  }
*/  

* 4. Drop last observations: Cannot be observed the following year
  drop if year == 2020  
  drop if leave_FL == 1
  
   
* 3. Count relocations  
  bysort attenphyid: egen reloc = sum(relocate_FL)   
  egen avg = mean (reloc)
  egen tag= tag(attenphyid)
  egen tot = sum(tag)
  gen tag_rel = (tag==1 & reloc >0)
  egen tot_rel = sum(tag_rel) 
  display (1099/2013)
  drop tag tag_rel
  label var reloc "Number of relocations for each physician"
  label var avg "Avg number of relocations in the sample"
  label var tot "total number of Physicians in the sample"
  label var tot_rel "total number of Physicians s.t. reloc>0"
  br reloc avg tot tot_rel
  // A total of 2013 physians
  // 54.6% (1099) of Physicians in the sample relocated over the period
  // A Physician relocates in average 1.5 times
  
  
* 4. Declare Panel dataset
  xtset attenphyid_e year

* 5. Regressions  
 

*_____________________________ MODEL A _____________________________* 
  * Experience
  logit relocate_FL ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit0
  
  * Physician
  //1
  logit relocate_FL ptsday_binary ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit1
  
  //2
  logit relocate_FL tot_vol ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit2
   
  //3
  logit relocate_FL num_EDs ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit3 
  
  //4
  logit relocate_FL non_metro ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit4
    
  //5
  logit relocate_FL b4xtra_physemer_approved ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit5
  
  //1_5
  logit relocate_FL ptsday_binary pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit1_5 
  
  
  * Hospital Staffing
  //6
  logit relocate_FL c5_ftetotals ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit6   

  //7
  logit relocate_FL c5_fteemerge ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit7

  //8
  logit relocate_FL c6_ftehosptadm ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit8
  
  //9
  logit relocate_FL b4_numbphys ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit9
  
  //10
  logit relocate_FL b4_physemer ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit10
  
 
  * Hospital: Financial standing  
  //11
  logit relocate_FL c2_tot_margin ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit11
  
  //12
  logit relocate_FL c5_swfte_emerge ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit12

  //13
  logit relocate_FL c6_swresearexp ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit13

  //14
  logit relocate_FL c5_swfte_totals ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit14 

  //15
  logit relocate_FL c6_swfte_hosptadm ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit15


  * Wages
  //16
  logit relocate_FL pw_median ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit16

  //17
  logit relocate_FL pw_mean ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit17
  
  //18
  logit relocate_FL pw_95th ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit18
  
  //19
  logit relocate_FL benefits_per_FTE ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit19

  
  * Tract level
  //20
  logit relocate_FL total_population ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit20

  //21
  logit relocate_FL median_income ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit21
  
  //22
  logit relocate_FL poverty_binary ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit22

  //23
  logit relocate_FL house_value ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit23  

  //24
  logit relocate_FL ru2003 ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit24
  
  //20_24
  logit relocate_FL total_population median_income poverty_binary ///
  house_value ru2003 ib(0).experience
  eststo margin: margins, dydx(*) post
  est sto logit20_24
    


  *_____________________________ MODEL B: Fixed Effects _____________________________* 
  
/*

  * Experience
  logit relocate_FL ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit0
  
  * Physician
  //1
  logit relocate_FL ptsday_binary ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit1
  
  //2
  logit relocate_FL tot_vol ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit2
   
  //3
  logit relocate_FL num_EDs ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit3 
  
  //4
  xtlogit relocate_FL non_metro ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit4
    
  //5
  xtlogit relocate_FL b4xtra_physemer_approved ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit5
  
  //1_5
  xtlogit relocate_FL ptsday_binary pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit1_5 
  
  
  * Hospital Staffing
  //6
  xtlogit relocate_FL c5_ftetotals ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit6   

  //7
  xtlogit relocate_FL c5_fteemerge ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit7

  //8
  xtlogit relocate_FL c6_ftehosptadm ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit8
  
  //9
  xtlogit relocate_FL b4_numbphys ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit9
  
  //10
  xtlogit relocate_FL b4_physemer ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit10
  
 
  * Hospital: Financial standing  
  //11
  xtlogit relocate_FL c2_tot_margin ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit11
  
  //12
  xtlogit relocate_FL c5_swfte_emerge ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit12

  //13
  xtlogit relocate_FL c6_swresearexp ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit13

  //14
  xtlogit relocate_FL c5_swfte_totals ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit14 

  //15
  xtlogit relocate_FL c6_swfte_hosptadm ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit15


  * Wages
  //16
  xtlogit relocate_FL pw_median ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit16

  //17
  xtlogit relocate_FL pw_mean ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit17
  
  //18
  xtlogit relocate_FL pw_95th ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit18
  
  //19
  xtlogit relocate_FL benefits_per_FTE ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit19

  
  * Tract level
  //20
  xtlogit relocate_FL total_population ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit20

  //21
  xtlogit relocate_FL median_income ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit21
  
  //22
  xtlogit relocate_FL poverty_binary ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit22

  //23
  xtlogit relocate_FL house_value ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit23  

  //24
  xtlogit relocate_FL ru2003 ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit24
  
  //20_24
  xtlogit relocate_FL total_population median_income poverty_binary ///
  house_value ru2003 ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit20_24
    
*/
  

*_____________________________ MODEL C: Differencing _____________________________* 

/*
  * Experience
  xtlogit relocate_FL ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit0
  eststo odds_0: xtlogit relocate_FL ib(0).experience, or

  
  * Physician
  //1
  xtlogit relocate_FL ptsday_binary ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit1
  eststo odds_1: xtlogit relocate_FL ptsday_binary ib(0).experience, or
  
  //2
  xtlogit relocate_FL tot_vol ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit2
  eststo odds_2: xtlogit relocate_FL tot_vol ib(0).experience, or
  
  //3
  xtlogit relocate_FL num_EDs ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit3 
  eststo odds_3: xtlogit relocate_FL num_EDs ib(0).experience, or
  
  //4
  xtlogit relocate_FL non_metro ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit4
  eststo odds_4: xtlogit relocate_FL non_metro ib(0).experience, or
  
  //5
  xtlogit relocate_FL b4xtra_physemer_approved ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit5
  eststo odds_5: xtlogit relocate_FL b4xtra_physemer_approved ib(0).experience, or
 
  //1_5
  xtlogit relocate_FL ptsday_binary pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit1_5 
  eststo odds1_5: xtlogit relocate_FL ptsday_binary pe tot_vol ///
  num_EDs non_metro b4xtra_physemer_approved ib(0).experience, or
  
  * Hospital Staffing
  //6
  xtlogit relocate_FL c5_ftetotals ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit6 
  eststo odds_6: xtlogit relocate_FL c5_ftetotals ib(0).experience, or
  //7
  xtlogit relocate_FL c5_fteemerge ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit7
  eststo odds_7: xtlogit relocate_FL c5_fteemerge ib(0).experience, or
  //8
  xtlogit relocate_FL c6_ftehosptadm ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit8
  eststo odds_8: xtlogit relocate_FL c6_ftehosptadm ib(0).experience, or
  //9
  xtlogit relocate_FL b4_numbphys ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit9
  eststo odds_9: xtlogit relocate_FL b4_numbphys ib(0).experience, or
  //10
  xtlogit relocate_FL b4_physemer ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit10
  eststo odds_10: xtlogit relocate_FL b4_numbphys ib(0).experience, or
/*  
  //6_10
  xtlogit relocate_FL c5_ftetotals c5_fteemerge c6_ftehosptadm ///
  b4_numbphys b4_physemer ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit6_10
  eststo odds6_10: xtlogit relocate_FL c5_ftetotals c5_fteemerge ///
  c6_ftehosptadm b4_numbphys b4_physemer ib(0).experience, or
*/  
 
  * Hospital: Financial standing  
  //11
  xtlogit relocate_FL c2_tot_margin ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit11
  eststo odds_11: xtlogit relocate_FL c2_tot_margin ib(0).experience, or
  //12
  xtlogit relocate_FL c5_swfte_emerge ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit12
  eststo odds_12: xtlogit relocate_FL c5_swfte_emerge ib(0).experience, or
  //13
  xtlogit relocate_FL c6_swresearexp ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit13
  eststo odds_13: xtlogit relocate_FL c6_swresearexp ib(0).experience, or
  //14
  xtlogit relocate_FL c5_swfte_totals ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit14
  eststo odds_14: xtlogit relocate_FL c5_swfte_totals ib(0).experience, or
  //15
  xtlogit relocate_FL c6_swfte_hosptadm ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit15
  eststo odds_15: xtlogit relocate_FL c6_swfte_hosptadm ib(0).experience, or

  * Wages
  //16
  xtlogit relocate_FL pw_median ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit16
  eststo odds_16: xtlogit relocate_FL pw_median ib(0).experience, or
  //17
  xtlogit relocate_FL pw_mean ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit17
  eststo odds_17: xtlogit relocate_FL pw_mean ib(0).experience, or
  //18
  xtlogit relocate_FL pw_95th ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit18
  eststo odds_18: xtlogit relocate_FL pw_95th ib(0).experience, or
  //19
  xtlogit relocate_FL benefits_per_FTE ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit19
  eststo odds_19: xtlogit relocate_FL benefits_per_FTE ib(0).experience, or

  
  * Tract level
  //20
  xtlogit relocate_FL total_population ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit20
  eststo odds_20: xtlogit relocate_FL total_population ///
  ib(0).experience, or
  //21
  xtlogit relocate_FL median_income ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit21
  eststo odds_21: xtlogit relocate_FL median_income ib(0).experience, or
  //22
  xtlogit relocate_FL poverty_binary ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit22
  eststo odds_22: xtlogit relocate_FL poverty_binary ib(0).experience, or
  //23
  xtlogit relocate_FL house_value ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit23
  eststo odds_23: xtlogit relocate_FL house_value ib(0).experience, or
  //24
  xtlogit relocate_FL ru2003 ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit24
  eststo odds_24: xtlogit relocate_FL ru2003 ib(0).experience, or
  //20_24
  xtlogit relocate_FL total_population median_income poverty_binary ///
  house_value ru2003 ib(0).experience, fe
  eststo margin: margins, dydx(*) post
  est sto logit20_24
  eststo odds20_24: xtlogit relocate_FL total_population median_income ///
  poverty_binary house_value ru2003 ib(0).experience, or
  
*/
  

  
* 6. Exports

  * Logit Table 0 
  esttab logit0 ///
  using ${results}logit_estimates_0.tex, label ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) mtitles() ///
//   indicate("Experience Fixed-Effects = *.experience") ///
  title("Marginal effects - Physician work volume: Logit Estimation of Florida ED physicians' relocation patterns between 2006 and 2020") replace

  * Logit Table 1  
  esttab logit1 logit2 logit3 logit4 logit5 logit1_5 ///
  using ${results}logit_estimates_1.tex, label ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  alignment(D{.}{.}{-1}) mtitles() ///
  /// //   indicate("Experience Fixed-Effects = *.experience") ///
  title("Marginal effects - Physician work volume: Logit Estimation of Florida ED physicians' relocation patterns between 2006 and 2020") replace
 
  * Logit Table 2 
  esttab logit6 logit7 logit8 logit9 logit10 ///
  using ${results}logit_estimates_2.tex, label ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  /// //   indicate("Experience Fixed-Effects = *.experience") ///
  alignment(D{.}{.}{-1}) mtitles() /// 
  title("Marginal effects - Hospital staffing: Logit Estimation of Florida ED physicians' relocation patterns between 2006 and 2020") replace

  * Logit Table 3 
  esttab logit11 logit12 logit13 logit14 logit15  ///
  using ${results}logit_estimates_3.tex, label ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  /// //   indicate("Experience Fixed-Effects = *.experience") ///
  alignment(D{.}{.}{-1}) mtitles() /// 
  title("Marginal effects - Hospital financial standing: Logit Estimation of Florida ED physicians' relocation patterns between 2006 and 2020") replace
  
  * Logit Table 4 
  esttab logit16 logit17 logit18 logit19 ///
  using ${results}logit_estimates_4.tex, label ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  /// //   indicate("Experience Fixed-Effects = *.experience") ///
  alignment(D{.}{.}{-1}) mtitles() /// 
  title("Marginal effects - Med. Wages in zip code: Logit Estimation of Florida ED physicians' relocation patterns between 2006 and 2020") replace
  
  * Logit Table 5 
  esttab logit20 logit21 logit22 logit23 logit24 ///
  using ${results}logit_estimates_5.tex, label ///
  b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) /// 
  labels("\$Pseudo R^2\$" "\$N\$")) /// 
  /// //   indicate("Experience Fixed-Effects = *.experience") ///
  alignment(D{.}{.}{-1}) mtitles() /// 
  title("Marginal effects - Tract level: Logit Estimation of Florida ED physicians' relocation patterns between 2006 and 2020") replace
  


