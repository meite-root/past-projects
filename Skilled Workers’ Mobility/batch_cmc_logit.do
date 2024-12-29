/*========================================================================
Title: 6_Analysis_3_choicemodel.do
Author: Hassane Meite
Date created: Tue 4 Apr 2023
Date last updated: Fri 28  Jul 2023
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

  display c(current_time) 
  

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
  
* 3.Conditional logit estimation 
  cmset id alternative // Declare data to be cross-sectional choice model data
  
  // regression 1
  eststo table1: cmclogit choice i.control_notfp i.control_invst, iter(20)
  
  // regression 2
  eststo table2: cmclogit choice i.control_notfp##i.exp_bin i.control_invst##i.exp_bin, iter(20)
  
 