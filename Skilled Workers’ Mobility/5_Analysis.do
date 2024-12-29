/*==============================================================================
Title: 5_Analysis.do
Author: Hassane Meite
Date created: Mon 9 May
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
  
* Set folder subdirectories
  global edlaims "${path}/ED_claims/"
  global code "${path}/code/Hassane/"
  global data "${path}/FL_Hospital_Financial_Data/all_raw/"
  global merged "${path}/FL_Hospital_Financial_Data/stata/"
  global sheets "${path}/FL_Hospital_Financial_Data/stata/sheets/"
  global results "${path}/results/Hassane/"

* Initialize log
  log using ${code}5_Analysis.log, replace
  display c(current_time) 
  

*===============================================================================
* 1. Physicians Cohorts
*===============================================================================

forvalues u=2014(-1)2008 { 
  
*===============================================================================
* 1. Physicians Cohorts
*===============================================================================
  local i = `u'+ 6
  display "" 
  display "--------------" 
  display "Start year: " `u' 
  display "End year: " `i'
  display "--------------" 
  display "" 
 
  
* 1.Load dataset of all cohorts of ED physicians
  use "${edclaims}new_ED_physicians_2006_to_2014.dta", clear
  describe
 
* 2.Keep relevant variables
  keep attenphyid start_year end_year num_EDs_start num_EDs_end ///
  vol_per_ED1_start ed_faclnbr1_start vol_per_ED1_end ed_faclnbr1_end 
 
* 3.Select Cohort
  keep if start_year == `u'
 13.   describe
 14.   tab ed_faclnbr1_end, missing
 15.   save tempphys.dta, replace
 16.   
. *===============================================================================
. * 2. Add financial information 
. *===============================================================================
. 
. /*
>   Issue: 
> * fclnbr does not uniquely identify observations in hospital financial+geo data (FL_EDs_neighbor_finance_20__.dta files). 
> —> ed_fclnbr (almost) does 
> —> Only the main observation of all duplicates have a client code and name
> —> Only the main observation of all duplicates is onsite
> 
> * what I did: 
> —> drop all offsite locations
> -> drop special cases
> */  
. 
. * 1.Clean financial and geographic data for merge
.   // Start year financial info
.   use ${financial}FL_EDs_neighbor_finance_`u'.dta, clear 
 17.   drop if offsiteed == 1 // drop all offsite locations 
 18.   drop if faclnbr == "100075" & TRACTCE10 == "002700" // Special cases:
 19.   drop if faclnbr == "100252" & TRACTCE10 == "910500" // Special cases
 20.   save tempfin1.dta, replace
 21.   // End year financial info
.   use ${financial}FL_EDs_neighbor_finance_`i'.dta, clear 
 22.   drop if offsiteed == 1 // drop all offsite locations 
 23.   drop if faclnbr == "100075" & TRACTCE10 == "002700" // Special cases:
 24.   drop if faclnbr == "100252" & TRACTCE10 == "910500" // Special cases
 25.   save tempfin2.dta, replace
 26. 
. * 2.Merge financial information for starting ED
.   use tempphys, clear
 27.   describe
 28.   
.   // Start year info merge
.   rename ed_faclnbr1_start ed_faclnbr
 29.   merge m:1  ed_faclnbr using tempfin1.dta, ///
>   keepusing(c2_tot_margin c5_swemerge c6_swresearexp num_facilities) nogen keep(3)
 30.   rename ed_faclnbr ed_faclnbr1_start
 31.   rename (c2_tot_margin - num_facilities) start_= //  add prefix "start"
 32.   
.   // End year info merge
.   rename ed_faclnbr1_end ed_faclnbr
 33.   merge m:1  ed_faclnbr using tempfin2.dta, ///
>   keepusing(LICENSENUMBER c2_tot_margin c5_swemerge c6_swresearexp num_facilities)
 34.   // Keep all hospitals from the set of choices
.   drop if _merge==1
 35.   drop _merge
 36.   replace start_year= `u'
 37.   replace end_year= `i'
 38.   rename ed_faclnbr ed_faclnbr1_end
 39.   rename (LICENSENUMBER - num_facilities) end_= // add prefix "end"  
 40.   
.   // Erase temp files
.   erase tempfin1.dta
 41.   erase tempfin2.dta
 42. 
.   
. // * 3. Adjust financial information to reflect the fact that there are multiple facilities under one license number
. //   replace start_c2_tot_margin = start_c2_tot_margin/start_num_facilities 
. //   replace start_c5_swemerge = start_c5_swemerge/start_num_facilities
. //   replace start_c6_swresearexp = start_c6_swresearexp/start_num_facilities
. //  
. //   replace end_c2_tot_margin = end_c2_tot_margin/end_num_facilities
. //   replace end_c5_swemerge = end_c5_swemerge/end_num_facilities
. //   replace end_c6_swresearexp = end_c6_swresearexp/end_num_facilities
. 
. * 3.1. Rescale variables to millions of dollars
.   replace start_c2_tot_margin = start_c2_tot_margin/1000000 
 43.   replace start_c5_swemerge = start_c5_swemerge/1000000
 44.   replace start_c6_swresearexp = start_c6_swresearexp/1000000
 45.  
.   replace end_c2_tot_margin = end_c2_tot_margin/1000000
 46.   replace end_c5_swemerge = end_c5_swemerge/1000000
 47.   replace end_c6_swresearexp = end_c6_swresearexp/1000000
 48. 
.   
. * 4. save  
.   if `u' == 2014 {
 49.         compress
 50.         save ${merged}merged_ED_physicians_2008_to_2014.dta, replace
 51.         erase tempphys.dta
 52.         }
 53.         else {
 54.                 compress
 55.                 append using ${merged}merged_ED_physicians_2008_to_2014.dta, force
 56.                 // sort faclnbr flyear
.                 save ${merged}merged_ED_physicians_2008_to_2014.dta, replace
 57.                 erase tempphys.dta
 58.                 }
 59.                 
. }    

