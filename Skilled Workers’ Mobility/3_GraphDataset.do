/*==============================================================================
Title: 3_GraphDataset.do
Author: Hassane Meite
Date created: Mon 14 Mar
Date last updated:  Mon 14 Mar
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
  log using ${code}3_GraphDataset.log, replace
  


*===============================================================================
* A. Subset dataset
*===============================================================================

* Load data
  clear
  use ${merged}fl_all.dta

* Create subset of hospitals with ED departments
  use ${merged}fl_all.dta
  destring a2_ed_inhous, force replace
  destring a2_ed_oncall, force replace
  gen counthosps = 1
  gen ed_hospital = (a2_ed_inhous >=1 | a2_ed_oncall >=1)
  save ${merged}fl_all_temp.dta, replace
  keep if ed_hospital == 1
  save ${merged}fl_EDs_temp.dta, replace
    
* check specific variables
  tab flyear
  

*===============================================================================
* A. Graphs
*===============================================================================

* Graph 1: Number of Hospitals in the dataset over the years
  clear
  use ${merged}fl_all_temp.dta
  collapse (sum) counthosps (sum) ed_hospital, by (flyear)
  list  
  graph twoway connected counthosps ed_hospital flyear, ///
  legend(label(1 "Hospitals total")label(2 "Hospitals with ED departments")) 
  graph export ${results}1.Hospitals_totals.png, as(png) replace

* Graph 2:  Unique zipcode locations
  clear
  use ${merged}fl_EDs_temp.dta
  collapse (sum) counthosps, by (flyear a1_zip)
  replace counthosps = 1
  collapse (sum) unique_zipcodes=counthosps, by (flyear)
  
  graph twoway connected unique_zipcodes flyear, ///
  title("Unique zipcode locations") ///
  subtitle("Totals, 2004-2020") ///
  ytitle("Total number unique zipcode locations")
  graph export ${results}2.ED_Hospitals_unique_zipcode_locations.png, as(png) replace
  
  
* Graph 3: Total Operating Revenue 
  clear
  use ${merged}fl_EDs_temp.dta
  collapse (sum) totalrev=c2_tot_oper_rev (mean) meanrev=c2_tot_oper_rev, by (flyear)
  gen total_revenues = totalrev/10^9 
  gen average_revenues = meanrev/10^9 
  list total_revenues average_revenues
  
  graph twoway /// 
  (connected total_revenues flyear, yaxis(1)) ///
  (connected average_revenues flyear, yaxis(2)), ///
  title("Total Operating Revenue - C2") ///
  subtitle("2004-2020") ///
  ytitle("Total revenues ($ billions)") ///
  ytitle("Average revenues ($ billions)", axis(2)) ///
  legend(label(1 "Total revenues")label(2 "Average revenues")) 
  graph export ${results}3.ED_Hospitals_revenues.png, as(png) replace
  

* Graph 4: Total Operating Expense 
  clear
  use ${merged}fl_EDs_temp.dta
  collapse (sum) totalexp=c2_tot_oper_cost (mean) meanexp=c2_tot_oper_cost, by (flyear)
  gen total_expense = totalexp/10^9 
  gen average_expense = meanexp/10^9 
  list total_expense average_expense
  
  graph twoway /// 
  (connected total_expense flyear, yaxis(1)) ///
  (connected average_expense flyear, yaxis(2)), ///
  title("Total Operating Expense - C2") ///
  subtitle("2004-2020") ///
  ytitle("Total expense ($ billions)") ///
  ytitle("Average expense ($ billions)", axis(2)) ///
  legend(label(1 "Total expense")label(2 "Average expense")) 
  graph export ${results}4.ED_Hospitals_expense.png, as(png) replace
    
* Graph 5:  Active Staff
  clear
  use ${merged}fl_EDs_temp.dta
  destring b4_numbphys, force replace
  collapse (sum) total_staff=b4_numbphys, by (flyear)
  
  graph twoway connected total_staff flyear, ///
  title("Medical staff - B4") ///
  subtitle("Totals, 2004-2020") ///
  ytitle("Total number of active medical staff") ///
  legend(label(1 "Medical staff")) 
  graph export ${results}5.ED_Hospitals_medical_staff.png, as(png) replace
    
     
  
erase ${merged}fl_all_temp.dta
erase ${merged}fl_EDs_temp.dta    
***********  
  log close
