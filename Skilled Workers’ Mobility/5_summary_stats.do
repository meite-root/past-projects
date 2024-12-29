/*==============================================================================
Title: 5_Summary_stats.do
Author: Hassane Meite
Date created: Sun 10 April
Date last updated: Tue 13 Dec
================================================================================*/

*===========================================================================
* 0. Set Global paths and create a log file for results
*===========================================================================

  cap log close
  clear
  set more off
  ssc install estout

* Set path
  
  global path "/data/jv947/Lab_Shared"

* Set folder subdirectories  
  global edclaims "${path}/ED_claims/"
  global edphys "${path}/ED_claims/phys_cohorts/"
  global code "${path}/code/Hassane/"
  global data "${path}/FL_Hospital_Financial_Data/all_raw/"
  global merged "${path}/FL_Hospital_Financial_Data/stata/"
  global sheets "${path}/FL_Hospital_Financial_Data/stata/sheets/"
  global results "${path}/results/Hassane/"
  global financial "${path}/Master_FL_Hospital_List/working_data/"
  global licensedata "${path}/FL_Medical_License_Data/"
  
* Initialize log
  log using ${code}5_Summary_stats.log, replace
  display c(current_time) 
  

  
*===========================================================================
* 1. Summary Statistics - ED physicians
*===========================================================================

* 1. Load dataset 
  use ${merged}EM_physician_years_2006_to_2020.dta, clear
  // keep relevant variables
  keep attenphyid_e start_year year work ///
  mfulltime tot_vol num_EDs leave_FL relocate_FL experience
  gen obsyears= experience+1
  
* 2. Summary variables  
  bysort attenphyid_e: egen relocations = sum(relocate_FL)   
  bysort attenphyid_e: egen avgwork_vol = mean(tot_vol)
  bysort attenphyid_e: egen avgnum_EDs = mean(num_EDs)
  bysort attenphyid_e: egen observed = max(obsyears)
  
  egen tag= tag(attenphyid_e)
  gen tag_rel = (tag==1 & relocations>=1)
  egen tot = sum(tag)
  egen tot_reloc = sum(tag_rel)
  replace avgwork_vol = avgwork_vol*1000
  drop if tag==0
  egen avgreloc = mean (relocations)
  
  label var relocations "Number of relocations"
  label var avgwork_vol "Average work volume per year"
  label var avgnum_EDs "Average number of Practive EDs per year"
  label var observed "Number of years of observation"
  label var avgreloc "Avg number of relocations in the sample"
  label var tot "total number of Physicians in the sample"
  label var tot_reloc "total number of Physicians who relocated at least once in the sample"
   
* 3. Summary statistics 
  // keep only one observation per physician
  
  
  // summarize
  eststo full: quietly estpost summarize ///
		avgwork_vol avgnum_EDs relocations observed
  eststo relocate_y: quietly estpost summarize ///
		avgwork_vol avgnum_EDs relocations observed ///
		if relocations >0
  eststo relocate_n: quietly estpost summarize ///
		avgwork_vol avgnum_EDs relocations observed ///
		if relocations ==0
  
  gen count=1
  bysort start_year: egen totalyear = sum(count)
  latabstat totalyear avgwork_vol avgnum_EDs relocations observed, ///
  statistics(mean) by(start_year) tf(${results}summary_stats_physicians2) replace
     
 
  
* 5. Export		
  esttab test ///
  using ${results}summary_stats_physicians2.tex, ///
  title("Summary statistics: Florida Emergency Medicine Physicians, 2006-2020") ///
  label replace
  
  * 5. Export		
  esttab full relocate_y relocate_n ///
  using ${results}summary_stats_physicians.tex, ///
  title("Summary statistics: Florida Emergency Medicine Physicians, 2006-2020") ///
  mtitle ("Full sample" "Relocated at least once" "Never Relocated") ///
  cells ("mean (pattern (1 1 1) fmt (%4.1f)) sd (pattern (1 1 1) fmt (%4.1f))") ///
  label replace
  
*========================================================================== 
* 2. Summary Statistics - Hospitals
*===========================================================================


* 1. Load dataset 
  use ${merged}EM_physician_years_2006_to_2020.dta, clear
  // identify each hospital-year
  egen tag= tag(ed_faclnbr year)
  drop if tag== 0
  // drop irrelevant varibales
  drop attenphyid attenphynpi endpoint attenphyid_e start_year ///
  work vol_per_ED_yr mfulltime tot_vol num_EDs leave_FL relocate_FL ///
  experience
  // sort 
  order ed_faclnbr year
  sort ed_faclnbr year

* 2. Summary variables  
  *-> Main
  bysort ed_faclnbr: egen patiensdaily = mean(ptsday)   
  bysort ed_faclnbr: egen private_eq = max(pe)
  bysort ed_faclnbr: egen health_ed = max(b4xtra_physemer_approved)
  label var patiensdaily "Average number of patients per day (EM)"
  label var private_eq "Private equity contract"
  label var health_ed "Approved program EM Health Ed. program"

  *-> Hospital: staff in numbers
  bysort ed_faclnbr: egen staff_total = mean(c5_ftetotals)   
  bysort ed_faclnbr: egen staff_admin = mean(c6_ftehosptadm)
  bysort ed_faclnbr: egen staff_physicians = mean(b4_numbphys)
  bysort ed_faclnbr: egen staff_EDphysicians = mean(b4_physemer)  
  label var staff_total "Total No. of employees"
  label var staff_admin "Total No. of admin staff"
  label var staff_physicians "Total Number of physicians"
  label var staff_EDphysicians "Number of EM physicians"
  
  *-> Hospital: Financial standing
  bysort ed_faclnbr: egen net_revenue = mean(c2_tot_margin)   
  bysort ed_faclnbr: egen salary_emerg = mean(c5_swfte_emerge)
  bysort ed_faclnbr: egen salary_total = mean(c5_swfte_totals)
  bysort ed_faclnbr: egen salary_admin = mean(c6_swfte_hosptadm)  
  label var net_revenue "Hospital net Revenue (\$M)"
  label var salary_emerg "Salary expense per FTE - EM. S. (\$k)"
  label var salary_total "Salaries expense per FTE - Total (\$k)"
  label var salary_admin "Salaries expense per FTE - H. Admin. (\$k)"
  
  *-> Tract level
  bysort ed_faclnbr: egen tractpop = mean(total_population)   
  bysort ed_faclnbr: egen medianwage_med = mean(pw_median)
  bysort ed_faclnbr: egen poverty_rate = mean(poverty)
  bysort ed_faclnbr: egen house_median = mean(house_value)
  bysort ed_faclnbr: egen non_metro_area = max(ru2003)
  replace non_metro_area = (non_metro_area>=4)
  label var tractpop "Estimate Total population per tract (\$k)"
  label var medianwage_med "Zip Code Prevailing medical wage median (\$k)"
  label var poverty_rate "Poverty rate in tract"
  label var house_median "Median house value in tract (\$k)"
  label var non_metro_area "Hospital located in non_metro area"

* 3. Summary statistics 
  // keep only one observation per physician
  drop tag
  egen tag= tag(ed_faclnbr)
  drop if tag==0
  
  
  replace poverty_rate = poverty_rate/100
  
  
  // summarize
  eststo full: quietly estpost summarize /// 
  patiensdaily private_eq health_ed ///
  staff_total staff_admin staff_physicians staff_EDphysicians ///
  net_revenue salary_emerg salary_total salary_admin ///
  tractpop medianwage_med poverty_rate house_median non_metro_area
  
* 3. Export		
  esttab full ///
  using ${results}summary_stats_Hospitals.tex, ///
  refcat(patiensdaily " \rule{0pt}{4ex} \textit{Main}" ///
  staff_total "\rule{0pt}{4ex} \textit{Staff in numbers}" ///
  net_revenue "\rule{0pt}{4ex} \textit{Financial standing}" ///
  tractpop "\rule{0pt}{4ex} \textit{Tract Level}", nolabel) ///
  title("Summary statistics: Florida Emergency Departments, 2006-2020") ///
  mtitle ("Full sample" "Relocated at least once" "Never Relocated") ///
  cells ("mean (pattern (1 1 1) fmt (%4.2f)) sd (pattern (1 1 1) fmt (%4.1f))") ///
  label replace
  






  
  
*========================================================================== 
* 3. Summary Statistics - Balance tables
*===========================================================================

* 1. Load dataset 
  use ${merged}merged_ED_physicians_2006_to_2014.dta, clear

* 2. Drop observations that do not work in florida 
  drop if work_end == 0 

* 4. Reshape to long format
   reshape long ed_faclnbr num_EDs tot_vol vol_per_ED1 zip cpimed ///
   b4_physemer b4_numbphys c2_tot_margin c5_swemerge c5_swtotals c6_swresearexp ///
   c6_swapstgraded c6_swnpstgraded c6_swhosptadm ptsday ///
   benefits_per_FTE num_facilities ///
   c5_swfte_emerge c5_swfte_totals c6_swfte_researexp ///
   c6_swfte_apstgraded c6_swfte_npstgraded c6_swfte_hosptadm ///
   pw_median pw_mean pw_95th ///
   total_population total_housing occupied median_income ///
   poverty white black bachelors house_value median_age ///
   male_labor female_labor lpr_female lpr_male lbr_part ///
   pe b4xtra_physemer_approved, ///
   i(attenphyid attenphynpi start_year end_year work_end switch_end ///
   LICENSENUMBER) j(start_end) string


* 5. Adjust variables
  
  local vars c2_tot_margin c5_swemerge ///
  c5_swtotals c6_swapstgraded c6_swnpstgraded ///
  c6_swhosptadm c6_swresearexp ///
  c5_swfte_emerge c5_swfte_totals c6_swfte_researexp ///
  c6_swfte_apstgraded c6_swfte_npstgraded c6_swfte_hosptadm ///
  pw_median pw_mean pw_95th benefits_per_FTE ///
  median_income house_value
        
	foreach x of var `vars' { 
	replace `x' = `x'/cpimed
	}
 
* 6. Label variables
  * Physician Variables
  label var attenphyid "Physician ID"
  label var attenphynpi "Physician NPI"
  label var start_year "Starting year"
  label var end_year "End year" 
  label var work_end "=1 if working in FL at the end of the period"
  label var switch_end "=1 if phys switches primary work at the end of the period" 
  label var tot_vol "Work volume: Total number of patients (ks)"
  label var num_EDs "Number of EDs Physician works in"
  label var vol_per_ED "Total work volume per practice ED"
  * Hospital Variables
  label var ed_faclnbr "Facility ID number of the primary ED in given year" 
  label var cpimed "Medical cpi in given year. baseline:2006"
  label var pe "Private equity contract"
  label var ptsday "Patients per day"
  label var benefits_per_FTE "Benefits per full time employee"
  label var c2_tot_margin "c2 - Hospital net Revenue (Ms)"
  label var b4_numbphys "b4 - Total No. of physicians - Health Ed. Prorgams"
  label var b4_physemer "b4 - Number of EM physicians - Health Ed. Prorgams"
  label var b4xtra_physemer_approved "b4 - Approved program - EM (y/n)"
  label var c5_swemerge "c5 - Salary expense - Emerg. services (ks)"
  label var c5_swtotals "c5 - Salary expense - Tot. Patient Care Serv.(Ms)" 
  label var c6_swresearexp "c6 - Salary expense - research (ks)"
  label var c6_swapstgraded "c6 - Salary expense - approved GMEP (ks)"
  label var c6_swnpstgraded "c6 - Salary expense - non-approved GMEP (ks)"
  label var c6_swhosptadm "c6 - Salary expense - Hospital Admin. (ks)"
  // Per Full time employee
  label var c5_swfte_emerge "c5 - Salary expense per FTE - Em. S"
  label var c5_swfte_totals "c5 - Salaries expense per FTE - Total"
  label var c6_swfte_researexp  "c6 - Salaries expense per FTE - research"
  label var c6_swfte_apstgraded "c6 - Salaries expense per FTE - app. GMEP"
  label var c6_swfte_npstgraded "c6 - Salaries expense per FTE - n-app GMEP"
  label var c6_swfte_hosptadm "c6 - Salaries expense per FTE - H. Admin."
  * Zip-code level Health workers income
  label var pw_median "Zip Code Prevailing wage median (ks)"
  label var pw_mean "Zip Code Prevailing wage mean (ks)"
  label var pw_95th "Zip Code Prevailing wage 95th perc. (ks)"
  * Tract level
  label var median_income "Total Median Income per tract (ks)" 
  label var total_population "Estimate Total population per tract"
  label var poverty "Poverty rate per tract"
  label var white "Percentage white populaiton per tract"
  label var black "Percentage Black population per tract"
  label var bachelors "Percentage with Bachelors or higher"
  label var house_value "Median house value per tract"
  

* 7. Setup variables to export   
  global COVS1 ///
  b4_physemer b4_numbphys b4xtra_physemer_approved c2_tot_margin c5_swemerge  ///
  c5_swfte_emerge c5_swtotals c5_swfte_totals c6_swresearexp ///
  c6_swfte_researexp c6_swapstgraded c6_swfte_apstgraded ///
  c6_swnpstgraded c6_swfte_npstgraded c6_swhosptadm c6_swfte_hosptadm
   
  global COVS2 ///
  pe ptsday benefits_per_FTE total_population median_income poverty ///
  white black bachelors house_value pw_median pw_mean pw_95th
  
  
* 7. Export Table   	
  iebaltab $COVS1 , grpvar(start_end) rowvarlabels ///
  savetex("${results}salary_averages_6years_adj1.tex") replace
  
  iebaltab $COVS2 , grpvar(start_end) rowvarlabels ///
  savetex("${results}salary_averages_6years_adj2.tex") replace
  
 
/* Simple summary statistics:
  eststo not_working: quietly estpost summarize ///
		num_EDs_2013 num_EDs_2019 vol_tot_2013 vol_tot_2019 if work2019 ==0
  eststo still working: quietly estpost summarize ///
		num_EDs_2013 num_EDs_2019 vol_tot_2013 vol_tot_2019 if work2019 == 1

  esttab still_working not_working using ${results}summary_stats_EDphys.tex, ///
  cells ("mean (pattern (1 1 0) fmt (0)) sd (pattern (1 1 0) fmt (0)) min max") ///
  titles ("Still working in Florida in 2019" "No longer working in Florida in 2019") ///
  label replace
*/
 

*==========================================================================
* 4. Probavility distributions
*===========================================================================
 ssc install schemepack, replace
* 1. Load dataset 
  use ${merged}EM_physician_years_2006_to_2020.dta, clear
  // keep relevant variables
  keep attenphyid_e start_year year work ///
  mfulltime tot_vol num_EDs leave_FL relocate_FL experience
  
 
* 2. Summary statistics
  bysort experience: egen byexp_working = sum(work)
  bysort experience: egen byexp_relocations = sum(relocate_FL)
  bysort experience: egen byexp_leaving = sum(leave_FL)  
  collapse (mean) byexp_relocations (mean) byexp_leaving ///
  (mean) byexp_working, by (experience)   
  // Cumulative and total numbers    
  gen cumul_relocations=sum(byexp_relocations)
  egen tot_relocations=sum(byexp_relocations)
  gen cumul_leave=sum(byexp_leaving) 
  egen tot_leave=sum(byexp_leaving) 
  // Ratios
  gen prob_relocate = byexp_relocations/byexp_working
  gen prob_leave = byexp_leaving/byexp_working
  gen cumulprob_relocate = cumul_relocations/tot_relocations
  gen cumulprob_leave = cumul_leave/tot_leave
  // Label
  label var prob_relocate "Probability of relocating at given experience level"
  label var prob_leave "Probability of leaving FL at given experience level"
  label var cumulprob_relocate "Cumulative Probability of relocating"
  label var cumulprob_leave "Cumulative Probability of leaving FL"
  // Clean
  keep experience prob_relocate prob_leave ///
  cumulprob_relocate cumulprob_leave
  drop if experience == 14

  
* 3. Graph    
  // Graph 1: Relocations
  twoway connected prob_relocate experience, /// 
	title("Yearly Probability of Relocating Accross EDs") ///
	subtitle("Emergency Medicine Physicians cohorts 2006-2020") ///
	name(figure1, replace) scheme(white_brbg) 
  graph export ${results}6.yearly_relocation_prob_2006_2020.png, as(png) replace
    // Graph 2: Relocations -Cumulative
  twoway connected cumulprob_relocate experience, /// 
	title("Cumulative Probability of Relocating Accross EDs") ///
	subtitle("Emergency Medicine Physicians cohorts 2006-2020") ///
	name(figure1, replace)
  graph export ${results}"6.cumulative_relocation_prob_2006_2020.png", as(png) replace
  // Graph 3: Leaving FL
  twoway connected prob_leave experience, /// 
	title("Yearly Probability of Moving out of Florida") ///
	subtitle("Emergency Medicine Physicians cohorts 2006-2020") ///
	name(figure1, replace) scheme(white_brbg) 
  graph export ${results}6.yearly_leaving_prob_2006_2020.png, as(png) replace  
  // Graph 2: Leaving FL - Cumulative
  twoway connected cumulprob_leave experience, /// 
	title("Cumulative Probability of Moving out of Florida") ///
	subtitle("Emergency Medicine Physicians cohorts 2006-2020") ///
	name(figure1, replace)
  graph export ${results}"6.cumulative_leaving_prob_2006_2020.png", as(png) replace  
  
  /==========================================================================
* 4. Graphs
*===========================================================================

* Graph 1: Total numbers of hours of work in 2013 Vs in 2019  
  clear
  use ${edphys}ED_physicians_2013_to_2019.dta
  collapse (sum) vol_tot_start (sum) vol_tot_end
  graph bar vol_tot_start vol_tot_end, scheme(white_brbg) ///
  legend(order(1 "Hours worked in 2013 " 2 "Hours worked in 2019" ))
  graph export ${results}a1.ED_physicians_totalhours.png, as(png) replace
  
  // More hours worked in 2019 in total.

* Graph 2: Spread of number of EDs in which Doctors work in 2013 Vs in 2019  
  clear
  use ${edphys}ED_physicians_2013_to_2019.dta
  twoway ///
	(histogram num_EDs_start, width(1) color(green%30)) ///        
	(histogram num_EDs_end, width(1) color(red%30)), /// 
	title("Spread of number of EDs in which Physicians worked") ///
	subtitle("2013 Versus 2019") scheme(white_brbg) ///
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


