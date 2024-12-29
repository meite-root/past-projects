/*==============================================================================
Title: 2_MergeAppend.do
Author: Hassane Meite
Date created: Mon 7 Mar
Date last updated:  Mon 7 Mar
================================================================================*/

*===============================================================================
* 0. Set Global paths and create a log file for results
*===============================================================================

  cap log close
  clear
  set more off

* Set path
  global path "/data/jv947/Lab_Shared"

* Set folder subdirectories
  global code "${path}/code/Hassane/"
  global data "${path}/FL_Hospital_Financial_Data/all_raw/"
  global merged "${path}/FL_Hospital_Financial_Data/stata/"
  global sheets "${path}/FL_Hospital_Financial_Data/stata/sheets/"
  global results "${path}/results/Hassane/"

* Initialize log
  log using ${code}2_MergeAppend.log, replace
  display c(current_time)


*===============================================================================
* A. Compile data
*===============================================================================


forvalues i=2020(-1)2004 {
	
	clear
	use ${sheets}fl_`i'_A1-1.dta
	gen flyear = `i'
	label variable flyear "Year reported"
	order faclnbr flyear
	
	display "" 
	display "" 
	display "" 
	display "--------------" 
	display `i'
	display "--------------"
	display "" 
	display "" 
	display "" 
	
	display "" 
	display "Merging with A1"
	display "--------------" 
	merge 1:1  faclnbr using ${sheets}fl_`i'_A1-2.dta
	drop if _merge==2 // Not matched from using
	drop _merge

	
	display "" 
	display "Merging with A2"
	display "--------------" 
	merge 1:1  faclnbr using ${sheets}fl_`i'_A2.dta
	drop if _merge==2 // Not matched from using
	drop _merge

	
	display "" 
	display "Merging with B4"
	display "--------------" 
	merge 1:1  faclnbr using ${sheets}fl_`i'_B4.dta
	drop if _merge==2 // Not matched from using
	drop _merge

	
	display "" 
	display "Merging with B4xtra"
	display "--------------" 
	merge 1:1  faclnbr using ${sheets}fl_`i'_B4xtra.dta
	drop if _merge==2 // Not matched from using
	drop _merge

    
    display "" 
    display "Merging with C2"
    display "--------------" 
    merge 1:1  faclnbr using ${sheets}fl_`i'_C2.dta
	drop if _merge==2 // Not matched from using
	drop _merge
	
	
	display "" 
	display "Merging with C3a"
	display "--------------" 
	merge 1:1  faclnbr using ${sheets}fl_`i'_C3a.dta
	drop if _merge==2 // Not matched from using
	drop _merge

	
	display "" 
	display "Merging with C4"
	display "--------------" 
	merge 1:1  faclnbr using ${sheets}fl_`i'_C4.dta
	drop if _merge==2 // Not matched from using
	drop _merge
	
	
	display "" 
	display "Merging with C5"
	display "--------------" 
	merge 1:1  faclnbr using ${sheets}fl_`i'_C5.dta
	drop if _merge==2 // Not matched from using
	drop _merge
	
	
	display "" 
	display "Merging with C6"
	display "--------------" 
	merge 1:1  faclnbr using ${sheets}fl_`i'_C6.dta
	drop if _merge==2 // Not matched from using
	drop _merge
	
	display "" 
	display "Merging with C7"
	display "--------------" 
	if inrange(`i',2004,2018){ // There's no C-7 data for 2019 and 2020
	merge 1:1  faclnbr using ${sheets}fl_`i'_C7.dta, 
	drop if _merge==2 // Not matched from using
	drop _merge
	}
	
	display "" 
	display "Merging with E1a"
	display "--------------" 
	if inrange(`i',2004,2018){ // There's no E1a data for 2019 and 2020
	merge 1:1  faclnbr using ${sheets}fl_`i'_E1a.dta
	drop if _merge==2 // Not matched from using
	drop _merge
	}
	
	display "" 
	display "Merging with E1b"
	display "--------------" 
	if inrange(`i',2004,2018){ // There's no E1b data for 2019 and 2020
	merge 1:1  faclnbr using ${sheets}fl_`i'_E1b.dta
	drop if _merge==2 // Not matched from using
	drop _merge
	}
	
	display "" 
	display "Merging with X1"
	display "--------------" 
	merge 1:1  faclnbr using ${sheets}fl_`i'_X1.dta
	drop if _merge==2 // Not matched from using
	drop _merge
	
	sort faclnbr flyear // Order by hospital and year
	
	save ${merged}fl_`i'_allsheets.dta, replace
	
	if `i' == 2020 {
		compress
		save ${merged}fl_all.dta, replace
		}
		else {
			compress
			append using ${merged}fl_all.dta, force
			sort faclnbr flyear
			save ${merged}fl_all.dta, replace
			}
  }


  display c(current_time)
  log close
