/*========================================================================
Title: COVID_analysis.do
Author: Hassane Meite
**# Bookmark #1
Date created: Tue 4 Apr 2023
Date last updated: Thu 3 Aug 2023
========================================================================*/

*========================================================================
* 0. Set Global paths and create a log file for results
*=========================================================================

//  cd "/data/jv947/Lab_Shared/code/Hassane/"


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
  log using "${code}COVID_analysis.log", replace
  display c(current_time) 
  
  
  
  
  

*========================================================================
* 2019 and 2020 Retention Probabilities
*========================================================================


* 1. Load dataset 
  use ${merged}EM_physician_years_2006_to_2021.dta, clear   

* 2. Create new variables
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
  // Create leave variable, combining attrition and relocation
  gen leave_ED = (leave_FL ==1 | relocate_FL ==1 ) 

  
* 3. Adjusting to pre-2019
  /*
  Creating logit model's average predicted probability
  of relocation per hospital prior to 2019.
  */
  preserve 
  drop if year == 2020  
  drop if year == 2019 
  
* 5. Declare Panel dataset
  xtset attenphyid_e year
  
* 6. Regressions
  // Predict Hospital characteristics's BETAS on Physician relocation over time ; *expereince fixed effects  
  eststo main_3: logit leave_ED ptsday_binary_top pe tot_vol num_EDs non_metro b4xtra_physemer_approved b4_numbphys c5_swfte_totals adminexp_share ib(0).experience, vce(cluster year)
  eststo main_1: logit leave_ED ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved ib(0).experience, vce(cluster year)
  eststo main_2: logit leave_ED ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved b4_numbphys ib(0).experience, vce(cluster year)
  eststo main_4: logit leave_ED ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved b4_numbphys c5_swfte_totals adminexp_share pw_median ib(0).experience, vce(cluster year) 
  eststo main_5: logit leave_ED ptsday_binary_top pe tot_vol num_EDs b4xtra_physemer_approved b4_numbphys c5_swfte_totals adminexp_share pw_median ru2003 ib(0).experience, vce(cluster year)
  
  // Export
  esttab main_1 main_2 main_3 main_4 main_5 using ${results}covid_analysis.tex, eform label mtitles("Model 1" "Model 2" "Model 3" "Model 4" "Model 5") b(3) se(3) stats(r2_p N, fmt(%4.3f %9.0fc) labels("\$Pseudo R^2\$" "\$N\$")) indicate("Experience Fixed-Effects = *.experience") alignment(D{.}{.}{-1}) title("Logistic Regression - Florida ED physicians relocation and attrition  between 2006 and 2020") replace
 
 /*
* 7. Predicting 2019 probability of leaving hospital per physician
  restore
  keep if (year == 2019 |  year ==2020)
  gen leave_ED_prob = invlogit(_b[_cons] ///
  + _b[ptsday_binary_top] * ptsday_binary_top ///
  + _b[pe] * pe ///
  + _b[tot_vol] * tot_vol ///
  + _b[num_EDs] * num_EDs ///
  + _b[b4xtra_physemer_approved] * b4xtra_physemer_approved ///
  + _b[b4_numbphys] * b4_numbphys ///
  + _b[c5_swfte_totals] * c5_swfte_totals)
*/
  gen leave_ED_prob = invlogit(_b[_cons] + _b[ptsday_binary_top] * ptsday_binary_top + _b[pe] * pe  + _b[tot_vol] * tot_vol   + _b[num_EDs] * num_EDs  + _b[b4xtra_physemer_approved] * b4xtra_physemer_approved + _b[b4_numbphys] * b4_numbphys + _b[c5_swfte_totals] * c5_swfte_totals)

  
* 8. Prepare data for summary 
  // Predicted retention
  gen noleave_ED_prob = 1 - leave_ED_prob 
  // Actual retention
  gen noleave_ED = 1 - leave_ED
  // Physician count
  gen countphys = 1 
  
  
* 9. Collapse and save at the hospital level for 2019
  preserve
  keep if year == 2019  
  collapse (mean) p_ret2019=noleave_ED_prob (mean) ret2019=noleave_ED (sum)countphys2019=countphys, by(ed_faclnbr) 
  sort p_ret2019
  drop if missing(countphys2019)
  drop if missing(p_ret2019)
  drop if countphys2019<5
  label var ret2019 "2019-2020 actual retention rate "
  label var p_ret2019 "2019-2020 predicted retention rate"
  label var countphys2019 "Number of EM physicians - 2019" 	   
  save "${merged}covid_analysis_EDs_2019_retention.dta", replace
  
* 10. Collapse and save at the hospital level for 2020
  restore
  keep if year == 2020
  collapse (mean) p_ret2020=noleave_ED_prob (mean) ret2020=noleave_ED (sum)countphys2020=countphys, by(ed_faclnbr)
  sort p_ret2020
  drop if missing(countphys2020)
  drop if missing(p_ret2020)
  drop if countphys2020<5
  label var ret2020 "2020-2021 actual retention rate "
  label var p_ret2020 "2020-2021 predicted retention rate"
  label var countphys2020 "Number of EM physicians - 2020" 	
  save "${merged}covid_analysis_EDs_2020_retention.dta", replace
  

 
*========================================================================
* Comparison
*========================================================================
	  
* 1. Summary Statistics	
  use "${merged}covid_analysis_EDs_2019_retention.dta", clear  
  merge m:1 ed_faclnbr using "${merged}covid_analysis_EDs_2020_retention.dta"
  
  preserve
  gen probretention= p_ret2019 
  gen acturetention= ret2019
  gen physicians= countphys2019
  label var probretention "Predicted retention rate" 
  label var acturetention "Actual retention rate"
  label var physicians "Number of EM physicians" 	   
  drop if missing(countphys2019)
  eststo EDs2019: quietly estpost summarize probretention acturetention physicians
  
  restore
  gen probretention= p_ret2020
  gen acturetention= ret2020
  gen physicians= countphys2020
  label var probretention "Predicted retention rate"
  label var acturetention "Actual retention rate"
  label var physicians "Number of EM physicians" 	   
  drop if missing(countphys2020)
  eststo EDs2020: quietly estpost summarize probretention acturetention physicians
  
  esttab EDs2019 EDs2020 using ${results}COVID_analysis_summary_.tex, title("Summary statistics: Predicted and Actual Retention Rates") mtitle ("2019-2020" "2020-2021") cells ("mean (pattern (1 1 1) fmt (%5.3f))") label replace
 
* 2. Statistics & Plot
  use "${merged}covid_analysis_EDs_2019_retention.dta", clear  
  regress ret2019 p_ret2019  
  graph twoway (lfit ret2019 p_ret2019) (scatter ret2019 p_ret2019), yscale(range(0(0.2)1)) xscale(range(0.5(0.1)1))  saving(graph2019, replace)
  
  use "${merged}covid_analysis_EDs_2020_retention.dta", clear  
  regress ret2020 p_ret2020
  graph twoway (lfit ret2020 p_ret2020) (scatter ret2020 p_ret2020), yscale(range(0(0.2)1)) xscale(range(0.5(0.1)1)) saving(graph2020, replace)
  
  graph combine graph2019.gph graph2020.gph, col(1) iscale(1) title("Predicted and Actual Retention Rates, Years 2019 and 2020")
  graph export ${results}COVID_analysis_plot_main.png, replace 
  