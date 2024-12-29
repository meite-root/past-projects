/*==============================================================================
Title: 1_ImportFinancial_20002020.do
Author: Hassane Meite
Date created: Sat 19 Feb
Date last updated: Mon 21 Feb
================================================================================*/

/*==============================================================================
Task:
- We want to put together the hospital financial data from 2000-2020. It will give us a lot of good info on hospital performance, and some details about emergency department operations.
- The data dictionary is the Excel workbook under /data/FL_Hospital_Financial_Data/HSP_Financial_Workresults
- The challenge here is that there are a ton of variables. We don't necessarily need all of them.
        - Definitely include all info from A-1 (basic hospital characteristics)
        - Definitely include all info from C-2 (income statement)
        - Definitely include all info from C-3a (patient care revenues and deductions by payer)
        - Since this project is about physicians, I think we should include all info from B-4 on Medical Staff Profiles and C-7 on Physician's Revenue and Expenses
        - Since this project is about emergency departments, please pull every variable related to the emergency department on all other workresults
        - Pull any other variables that you think seem relevant / sound interesting / might matter for ED physician decision-making
- Please make sure to label all variables and give them somewhat intuitive names
- One of my past students put this data together. She didn't include all of the variables I mention here because the purpose of her project was different. She also included some variables that we don't necessarily need. Nevertheless, her code and resulting data set might be helpful to get you started. I put her files in the /code/ folder. 
- Note: We will add 2019-2020 data soon.
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
  log using ${code}1_ImportFinancial_20002020.log, replace
  display c(current_time) 

*===============================================================================
* 1. Extract A-1 info - GENERAL HOSPITAL INFORMATION - Part I
*===============================================================================

//  Based on Azemina's 
 
  
forvalues i=2004(1)2020 {

* 1. Import A1-2 sheet
  if inrange(`i',2013,2020){
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_HOSPITAL_INFO") firstrow allstring  clear
  } 
  else {
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_Hospital_Info") firstrow allstring  clear
  }
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"
  
* 4. Drop duplicate hospital observations;
  bysort FILE_NBR: ge N=_N
  tabulate N
  bysort FILE_NBR: keep if _n==1

* 5. Keep relevant variables 
  local a FILE_NBR report_to report_from FRASE_HOSP_NAME FRASE_ADDR1-FRASE_ZIP
  keep `a'
  order `a'
  describe // Data Check
  
* 6. Clean zip variable
  generate a1_zip = substr(FRASE_ZIP, 1, 5)
  drop FRASE_ZIP
  
* 6. Renaming & labeling variables
  rename FILE_NBR faclnbr
  
  rename FRASE_HOSP_NAME a1_hosp_name
  rename FRASE_ADDR1 a1_addr1
  rename FRASE_ADDR2 a1_addr2
  rename FRASE_ADDR3 a1_addr3
  rename FRASE_CITY a1_city
  rename FRASE_COUNTY a1_county
  rename FRASE_COUNTY_DESC a1_county_desc
  rename FRASE_STATE a1_state

  label var a1_hosp_name "Hospital Name"
  label var a1_addr1 "address - part 1"
  label var a1_addr2 "address - part 2"
  label var a1_addr3 "address - part 3"
  label var a1_city "city"
  label var a1_county "county"
  label var a1_county_desc "county_desc"
  label var a1_state "state"
  label var a1_zip "zip"
  label var report_from "Start dates for reporting period"
  label var report_to "End dates for reporting period"


* 7. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check
  
* 8. Save
  save ${sheets}fl_`i'_A1-1.dta, replace
  clear
  
}


*===============================================================================
* 2. Extract A1 info - GENERAL HOSPITAL INFORMATION - Part II
*===============================================================================

//  Based on Azemina's 
 
forvalues i=2004(1)2020 {

* 1. Import A1 sheet 
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_A1") firstrow allstring clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"
  
* 4. Drop duplicate hospital observations;
  bysort FILE_NBR: ge N=_N
  tabulate N
  bysort FILE_NBR: keep if _n==1

* 5. Keep relevant variables 
  local a FILE_NBR CONTROL_TYPE CONTROL_TYPE_ORGANIZATION ///
  CONTROL_TYPE_OWNER HOSP_TYPE-MANAGEMENT_CONTRACT_NAME MEDICARE_NO-TYPE_OF_HOSPITAL
  keep `a'
  order `a' 
  describe // Data Check
  
* 6. Renaming & labeling variables  
  rename FILE_NBR faclnbr

  local v CONTROL_TYPE CONTROL_TYPE_ORGANIZATION ///
  CONTROL_TYPE_OWNER HOSP_TYPE-MANAGEMENT_CONTRACT_NAME MEDICARE_NO-TYPE_OF_HOSPITAL
  foreach x of var `v' { 
  rename `x' a1_`x' 
  }
  rename *, lower
  
* 7. Arrange and re-check dataset
  destring a1_control_type, replace
  sort faclnbr
  describe // Data Check
  summarize // Data Check
  
* 8. Save
  save ${sheets}fl_`i'_A1-2.dta, replace
  clear
  
}



*===============================================================================
* 3. Extract A-2 info - SERVICES INVENTORY AND UNITS OF SERVICE REPORT
*===============================================================================


forvalues i=2004(1)2020 {

* 1. Import A2 sheet 
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_A2") firstrow allstring clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Pick the most recent record per hospital
  generate latest_date=date(report_from,"MDY")
  bysort FILE_NBR: egen max_date=max(latest_date)
  keep if max_date==latest_date
  drop max_date latest_date

* 4. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"
 
* 5. Drop duplicate hospital observations
  // Each hospital has multiple rows and each row is a different variable  
  bysort FILE_NBR LINE_NUMBER: ge N=_N
  tabulate N
  bysort FILE_NBR LINE_NUMBER: drop if _n>1
 
* 6. Drop unnecessary variables
  drop CLIENT_CODE N SUBMISSION_NUMBER report_to report_from SERVICE_CODE

* 7. Reshape Data
  // Reshape data such that each hospital has one row and multiple column variables
  destring LINE_NUMBER, force replace 
  reshape wide SERVICE_AMOUNT, i(FILE_NBR) j(LINE_NUMBER)
  describe // Data Check
  summarize // Data Check

* 8. Keep relevant variables 
  keep FILE_NBR SERVICE_AMOUNT10 SERVICE_AMOUNT11
  describe // Data Check
 
* 9. Renaming & labeling variables 
  rename FILE_NBR faclnbr
 
  rename SERVICE_AMOUNT10 a2_ed_inhous
  rename SERVICE_AMOUNT11 a2_ed_oncall
 
  label var a2_ed_inhous "number of visits - Emergency Services (24-Hour/Inhouse M.D.)"
  label var a2_ed_oncall "number of visits - Emergency Services (24-Hour/M.D. On-call)"

 
* 10. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check
 
* 11. Save
  save ${sheets}fl_`i'_A2.dta, replace
  clear
 
 
}



*===============================================================================
* 4. Extract B-4 info Medical Staff Profile
*===============================================================================

forvalues i=2004(1)2020 {

* 1. Import B-4 sheet 
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_B4") firstrow allstring  clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Pick the most recent record per hospital
  generate latest_date=date(report_from,"MDY")
  bysort FILE_NBR: egen max_date=max(latest_date)
  keep if max_date==latest_date
  drop max_date latest_date

* 4. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"
  
* 5. Drop duplicate hospital observations
  // Each hospital has multiple rows and each row is a different variable  
  // 22 hospitals have multiple submission numbers. Arlene Schawhn says hospitals have to resubmit if their data is incorrect
  bysort FILE_NBR LINE_NUMBER: ge N=_N
  tabulate N
  bysort FILE_NBR LINE_NUMBER: drop if _n>1
  
* 6. Drop unnecessary variables;
  drop CLIENT_CODE N SUBMISSION_NUMBER report_to report_from APPROVED_PROGRAM MEDICAL_STUDENTS RESIDENTS year

* 7. Reshape Data
  // Reshape data such that each hospital has one row and multiple column variables
  destring LINE_NUMBER, force replace 
  reshape wide ACTIVE_STAFF, i(FILE_NBR) j(LINE_NUMBER)
  describe // Data Check
  summarize // Data Check

* 8. Renaming & labeling variables 
  rename FILE_NBR faclnbr
  
  rename ACTIVE_STAFF1 b4_physfaml
  rename ACTIVE_STAFF2 b4_physpsyc
  rename ACTIVE_STAFF3 b4_physcpsy
  rename ACTIVE_STAFF4 b4_physprev
  rename ACTIVE_STAFF5 b4_physimmu
  rename ACTIVE_STAFF6 b4_physderm
  rename ACTIVE_STAFF7 b4_physimed
  rename ACTIVE_STAFF8 b4_physpedi
  rename ACTIVE_STAFF9 b4_physpulm
  rename ACTIVE_STAFF10 b4_physnucl
  rename ACTIVE_STAFF11 b4_physgast
  rename ACTIVE_STAFF12 b4_physemer
  rename ACTIVE_STAFF13 b4_physendo
  rename ACTIVE_STAFF14 b4_physhema
  rename ACTIVE_STAFF15 b4_physinfe
  rename ACTIVE_STAFF16 b4_physpend
  rename ACTIVE_STAFF17 b4_physphem
  rename ACTIVE_STAFF18 b4_physpnep
  rename ACTIVE_STAFF19 b4_physpcar
  rename ACTIVE_STAFF20 b4_physrhue
  rename ACTIVE_STAFF21 b4_physneph
  rename ACTIVE_STAFF22 b4_physneur
  rename ACTIVE_STAFF23 b4_physneon
  rename ACTIVE_STAFF24 b4_physonco
  rename ACTIVE_STAFF25 b4_physcard
  rename ACTIVE_STAFF26 b4_physdent
  rename ACTIVE_STAFF27 b4_physpodi
  rename ACTIVE_STAFF28 b4_physotol
  rename ACTIVE_STAFF29 b4_physopth
  rename ACTIVE_STAFF30 b4_physobst
  rename ACTIVE_STAFF31 b4_physurol
  rename ACTIVE_STAFF32 b4_physradi
  rename ACTIVE_STAFF33 b4_physrdia
  rename ACTIVE_STAFF34 b4_physrnuc
  rename ACTIVE_STAFF35 b4_physrthe
  rename ACTIVE_STAFF36 b4_physpath
  rename ACTIVE_STAFF37 b4_physpder
  rename ACTIVE_STAFF38 b4_physpblo
  rename ACTIVE_STAFF39 b4_physpfor
  rename ACTIVE_STAFF40 b4_physpneu
  rename ACTIVE_STAFF41 b4_physanes
  rename ACTIVE_STAFF42 b4_physsurg
  rename ACTIVE_STAFF43 b4_physsora
  rename ACTIVE_STAFF44 b4_physspla
  rename ACTIVE_STAFF45 b4_physsoth
  rename ACTIVE_STAFF46 b4_physstho
  rename ACTIVE_STAFF47 b4_physsneu
  rename ACTIVE_STAFF48 b4_physscar
  rename ACTIVE_STAFF49 b4_physothe
  rename ACTIVE_STAFF50 b4_numbphys
  
  label var b4_physfaml "Family Practice"
  label var b4_physpsyc "Psychiatry"
  label var b4_physcpsy "Psychiatry, Child"
  label var b4_physprev "Public Health / Preventive Medicines"
  label var b4_physimmu "Allergy and Immunology"
  label var b4_physderm "Dermatology"
  label var b4_physimed "Internal Medicine"
  label var b4_physpedi "Pediatrics"
  label var b4_physpulm "Pulmonary Diseases"
  label var b4_physnucl "Nuclear Medicine"
  label var b4_physgast "Gastroenterology"
  label var b4_physemer "Emergency Medicine"
  label var b4_physendo "Endocrinology"
  label var b4_physhema "Hematology"
  label var b4_physinfe "Infectious Diseases"
  label var b4_physpend "Pediatric Endocrinology"
  label var b4_physphem "Pediatric Hematology"
  label var b4_physpnep "Pediatric Nephrology"
  label var b4_physpcar "Pediatric Cardiology"
  label var b4_physrhue "Rhuematology"
  label var b4_physneph "Nephrology"
  label var b4_physneur "Neurology"
  label var b4_physneon "Neonatal / Perinatal Medicine"
  label var b4_physonco "Oncology, Medicine"
  label var b4_physcard "Cardiovascular Diseases / Cardiology"
  label var b4_physdent "Dental Medicine (DMD)"
  label var b4_physpodi "Podiatric Medicine / Surgery (DPM)"
  label var b4_physotol "Otolaryngology (E.N.T.)"
  label var b4_physopth "Opthalmology"
  label var b4_physobst "Obstetric and Gynecology"
  label var b4_physurol "Urological, Medicine / Surgery"
  label var b4_physradi "Radiology"
  label var b4_physrdia "Radiology, Diagnostic"
  label var b4_physrnuc "Radiology, Diagnostic / Nuclear"
  label var b4_physrthe "Radiology, Therapeutic"
  label var b4_physpath "Pathology"
  label var b4_physpder "Pathology, Dermatopathology"
  label var b4_physpblo "Pathology, Bloodbanking"
  label var b4_physpfor "Pathology, Forensic"
  label var b4_physpneu "Pathology, Neuropathology"
  label var b4_physanes "Anesthesiology"
  label var b4_physsurg "Surgery, General"
  label var b4_physsora "Surgery, Oral & Maxillofacial (DDS, MD)"
  label var b4_physspla "Surgery, Plastic"
  label var b4_physsoth "Surgery, Orthopedic"
  label var b4_physstho "Surgery, Thoracic"
  label var b4_physsneu "Surgery, Neurological"
  label var b4_physscar "Surgery, Cardiovascular"
  label var b4_physothe "Other Clinical Specialties *"
  label var b4_numbphys "Total Number of Physicians"

* 7. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check
  
* 8. Save
  save ${sheets}fl_`i'_B4.dta, replace
  clear
  
}



*===============================================================================
* 4a. Extract B-4 (+) info Medical Staff Profile (Line 12)
*===============================================================================

forvalues i=2004(1)2020 {

* 1. Import B-4 sheet 
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_B4") firstrow allstring  clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Pick the most recent record per hospital
  generate latest_date=date(report_from,"MDY")
  bysort FILE_NBR: egen max_date=max(latest_date)
  keep if max_date==latest_date
  drop max_date latest_date

* 4. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"
  
* 5. Drop duplicate hospital observations
  // Each hospital has multiple rows and each row is a different variable  
  // 22 hospitals have multiple submission numbers. Arlene Schawhn says hospitals have to resubmit if their data is incorrect
  foreach x of varlist APPROVED_PROGRAM-ACTIVE_STAFF {
  destring `x', force replace
  }
  bysort FILE_NBR LINE_NUMBER: ge N=_N
  tabulate N
  bysort FILE_NBR LINE_NUMBER: drop if _n>1
  
* 6. Drop unnecessary variables;
  drop CLIENT_CODE N SUBMISSION_NUMBER report_to report_from year
  

* 7. Reshape Data
  // Reshape data such that each hospital has one row and multiple column variables
  drop if LINE_NUMBER != "12"
  destring LINE_NUMBER, force replace 
  reshape wide APPROVED_PROGRAM-ACTIVE_STAFF, i(FILE_NBR) j(LINE_NUMBER)
  describe // Data Check
  summarize // Data Check

* 8. Renaming & labeling variables 
  rename FILE_NBR faclnbr
 
  rename APPROVED_PROGRAM12	b4xtra_physemer_approved
  rename MEDICAL_STUDENTS12 b4xtra_physemer_medstuds
  rename RESIDENTS12 b4xtra_physemer_residents
  rename ACTIVE_STAFF12 b4xtra_physemer_actvstaff
 
  label var b4xtra_physemer_approved "approved program - Emergency Medicine"
  label var b4xtra_physemer_medstuds "Medical Students - Emergency Medicine"
  label var b4xtra_physemer_residents "Residents - Emergency Medicine"
  label var b4xtra_physemer_actvstaff "Active staff - Emergency Medicine"


* 7. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check

* 8. Save
  save ${sheets}fl_`i'_B4xtra.dta, replace
  clear
 
}
 
 
 
 
*===============================================================================
* 5. Extract C-2 info - income statement
*===============================================================================

//  Based on Azemina's 


forvalues i=2004(1)2020 {

* 1. Import C-2 sheet 
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_C2") firstrow allstring  clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"
  
* 4. Drop duplicate hospital observations;
  // Each hospital has multiple rows and each row is a different variable  
  destring AMOUNT, force replace
  collapse (sum) AMOUNT, by(FILE_NBR LINE_NUMBER)
  bysort FILE_NBR LINE_NUMBER: ge N=_N
  tabulate N
  bysort FILE_NBR LINE_NUMBER: drop if _n>1
  drop N
  
* 5. Reshape Data
  // Reshape data such that each hospital has one row and multiple column variables
  destring LINE_NUMBER, force replace 
  reshape wide AMOUNT, i(FILE_NBR) j(LINE_NUMBER)
  describe // Data Check
  summarize // Data Check



* 6. Renaming & labeling variables
  rename FILE_NBR faclnbr
  
  rename AMOUNT1 c2_ip_rev
  rename AMOUNT2 c2_out_rev
  rename AMOUNT3 c2_tot_rev
  rename AMOUNT4 c2_tot_rev_ded
  rename AMOUNT5 c2_net_pat_care_rev
  rename AMOUNT6 c2_oth_oper_rev
  rename AMOUNT7 c2_tot_oper_rev
  rename AMOUNT8 c2_wages_pat_care_cost
  rename AMOUNT9 c2_oth_pat_care_cost
  rename AMOUNT10 c2_wages_admin_cost
  rename AMOUNT11 c2_oth_admin_cost
  rename AMOUNT12 c2_tot_oper_cost
  rename AMOUNT13 c2_oper_margin
  rename AMOUNT14 c2_nonoper_rev
  rename AMOUNT15 c2_nonoper_cost
  rename AMOUNT16 c2_excess_nonoper_rev
  rename AMOUNT17 c2_tot_gross_margin
  rename AMOUNT18 c2_taxes
  rename AMOUNT19 c2_extra_gains
  rename AMOUNT21 c2_extra_losses
  rename AMOUNT24 c2_tot_extra
  rename AMOUNT25 c2_tot_margin

  // Operating revenue
  label var c2_ip_rev "Inpatient Services Revenue (Worksheet C-3, Col(1), Line 54)"
  label var c2_out_rev "Outpatient Services Revenue (Worksheet C-3, Col(2), Line 54)"
  label var c2_tot_rev "Total Patient Service Revenue (Line 1 + Line 2)"
  // Operating deductions
  label var c2_tot_rev_ded "Total Deductions from Revenue (Worksheet C-3a, ACCT, C003, Col(4))"
  label var c2_net_pat_care_rev "Net Patient Care Revenue (Line 3 - Line 4)"
  label var c2_oth_oper_rev "Other Operating Revenue (Worksheet C-4, Col(1), Line 20)"
  label var c2_tot_oper_rev "Total Operating Revenue (Line 5 + Line 6)"
  // Operating costs/expenses
  label var c2_wages_pat_care_cost "Salaries and Wages-Patient Care (Worksheet C-5, Col(1), Line 54)"
  label var c2_oth_pat_care_cost "Other Expense-Patient Care (Worksheet C-5 Col(2), Line 54)"
  label var c2_wages_admin_cost "Salaries and Wages-Administrative & General (Worksheet C-6 Col(1), Line 37)"
  label var c2_oth_admin_cost "Other Expense-Administrative & General (Worksheet C-6 Col(2), Line 37)"
  label var c2_tot_oper_cost "Total Operating Expense (Lines 8 through Line 11)"
  label var c2_oper_margin "Operating Margin (Line 7 - Line 12)"
  // Nonoperating revenue and costs
  label var c2_nonoper_rev "Nonoperating Revenue (Worksheet C-4, Col(1), Line 34)"
  label var c2_nonoper_cost "Nonoperating Expense (Worksheet C-6, Col(3), Line 40)"
  label var c2_excess_nonoper_rev "Excess (Deficiency) of Nonoperating Revenues Over Nonoperating Expenses (Line 14 - Line 15)"
  label var c2_tot_gross_margin "Total Margin B/F Income Taxes & Extraordinary Items (Line 13 + Line 16)"
  label var c2_taxes "Provision for Incomes Taxes"
  // Extraordinary items
  label var c2_extra_gains "Extraordinary Gains *"
  label var c2_extra_losses "Extraordinary Losses *"
  label var c2_tot_extra "Total Extraordinary Items (Lines 19 + 21)"
  label var c2_tot_margin "Total Margin (Line 17 + 18 + 24)"

* 7. Drop remaining variables
  if `i' == 2016 { 
  	drop AMOUNT*
  } // year 2016 has extra amount items

* 8. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check
  
* 8. Save
  save ${sheets}fl_`i'_C2.dta, replace
  clear
  
}



*===============================================================================
* 6. Extract C-3a info - Statement of Patient Care Revenues and Deductions by Payer and Class of Care
*===============================================================================

//  Based on Azemina's 

forvalues i=2004(1)2020 {

* 1. Import C-3a sheet 
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_C3A") firstrow allstring  clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"
  
* 4. Drop duplicate hospital observations
  // Each hospital has multiple rows and each row is a different variable  
  foreach x of varlist INPATIENT_REVENUE-NET_PATIENT_REVENUE {
  destring `x', force replace
  }
  collapse (sum) INPATIENT_REVENUE-NET_PATIENT_REVENUE, by(FILE_NBR LINE_NUMBER)
  bysort FILE_NBR LINE_NUMBER: ge N=_N
  tabulate N
  bysort FILE_NBR LINE_NUMBER: drop if _n>1
  drop N
  
* 5. Reshape Data
  // Reshape data such that each hospital has one row and multiple column variables
  destring LINE_NUMBER, force replace 
  reshape wide INPATIENT_REVENUE-NET_PATIENT_REVENUE, i(FILE_NBR) j(LINE_NUMBER)
  describe // Data Check
  summarize // Data Check

* 6. Renaming & labeling variables
  /* Notes for renaming variables to keep similar conventions:
  -> Abbreviate Inpatient as ip
  -> Abbreviate Outpatient as op
  -> Abbreviate Total as tot
  -> Abbreviate Revenue as rev
  -> Abbreviate Deduction as ded */
  
  rename FILE_NBR faclnbr
  
  rename INPATIENT_REVENUE1 c3a_debt_ip_rev
  rename OUTPATIENT_REVENUE1 c3a_debt_op_rev
  rename TOTAL_REVENUE1 c3a_debt_tot_rev
  rename INPATIENT_DEDUCTION1 c3a_debt_ip_ded
  rename OUTPATIENT_DEDUCTION1 c3a_debt_op_ded
  rename TOTAL_DEDUCTION1 c3a_debt_tot_ded
  rename NET_INPATIENT_REVENUE1 c3a_debt_net_ip_rev
  rename NET_OUTPATIENT_REVENUE1 c3a_debt_net_op_rev
  rename NET_PATIENT_REVENUE1 c3a_debt_net_tot_rev
  
  rename INPATIENT_REVENUE2 c3a_self_ip_rev
  rename OUTPATIENT_REVENUE2 c3a_self_op_rev
  rename TOTAL_REVENUE2 c3a_self_tot_rev
  rename INPATIENT_DEDUCTION2 c3a_self_ip_ded
  rename OUTPATIENT_DEDUCTION2 c3a_self_op_ded
  rename TOTAL_DEDUCTION2 c3a_self_tot_ded
  rename NET_INPATIENT_REVENUE2 c3a_self_net_ip_rev
  rename NET_OUTPATIENT_REVENUE2 c3a_self_net_op_rev
  rename NET_PATIENT_REVENUE2 c3a_self_net_tot_rev
  
  rename INPATIENT_REVENUE3 c3a_charityhill_ip_rev
  rename OUTPATIENT_REVENUE3 c3a_charityhill_op_rev
  rename TOTAL_REVENUE3 c3a_charityhill_tot_rev
  rename INPATIENT_DEDUCTION3 c3a_charityhill_ip_ded
  rename OUTPATIENT_DEDUCTION3 c3a_charityhill_op_ded
  rename TOTAL_DEDUCTION3 c3a_charityhill_tot_ded
  rename NET_INPATIENT_REVENUE3 c3a_charityhill_net_ip_rev
  rename NET_OUTPATIENT_REVENUE3 c3a_charityhill_net_op_rev
  rename NET_PATIENT_REVENUE3 c3a_charityhill_net_tot_rev
  
  rename INPATIENT_REVENUE4 c3a_charityother_ip_rev
  rename OUTPATIENT_REVENUE4 c3a_charityother_op_rev
  rename TOTAL_REVENUE4 c3a_charityother_tot_rev
  rename INPATIENT_DEDUCTION4 c3a_charityother_ip_ded
  rename OUTPATIENT_DEDUCTION4 c3a_charityother_op_ded
  rename TOTAL_DEDUCTION4 c3a_charityother_tot_ded
  rename NET_INPATIENT_REVENUE4 c3a_charityother_net_ip_rev
  rename NET_OUTPATIENT_REVENUE4 c3a_charityother_net_op_rev
  rename NET_PATIENT_REVENUE4 c3a_charityother_net_tot_rev
  
  rename INPATIENT_REVENUE5 c3a_convmedicare_ip_rev
  rename OUTPATIENT_REVENUE5 c3a_convmedicare_op_rev
  rename TOTAL_REVENUE5 c3a_convmedicare_tot_rev
  rename INPATIENT_DEDUCTION5 c3a_convmedicare_ip_ded
  rename OUTPATIENT_DEDUCTION5 c3a_convmedicare_op_ded
  rename TOTAL_DEDUCTION5 c3a_convmedicare_tot_ded
  rename NET_INPATIENT_REVENUE5 c3a_convmedicare_net_ip_rev
  rename NET_OUTPATIENT_REVENUE5 c3a_convmedicare_net_op_rev
  rename NET_PATIENT_REVENUE5 c3a_convmedicare_net_tot_rev
  
  rename INPATIENT_REVENUE6 c3a_convmedicaid_ip_rev
  rename OUTPATIENT_REVENUE6 c3a_convmedicaid_op_rev
  rename TOTAL_REVENUE6 c3a_convmedicaid_tot_rev
  rename INPATIENT_DEDUCTION6 c3a_convmedicaid_ip_ded
  rename OUTPATIENT_DEDUCTION6 c3a_convmedicaid_op_ded
  rename TOTAL_DEDUCTION6 c3a_convmedicaid_tot_ded
  rename NET_INPATIENT_REVENUE6 c3a_convmedicaid_net_ip_rev
  rename NET_OUTPATIENT_REVENUE6 c3a_convmedicaid_net_op_rev
  rename NET_PATIENT_REVENUE6 c3a_convmedicaid_net_tot_rev
  
  rename INPATIENT_REVENUE7 c3a_othergovt_ip_rev
  rename OUTPATIENT_REVENUE7 c3a_othergovt_op_rev
  rename TOTAL_REVENUE7 c3a_othergovt_tot_rev
  rename INPATIENT_DEDUCTION7 c3a_othergovt_ip_ded
  rename OUTPATIENT_DEDUCTION7 c3a_othergovt_op_ded
  rename TOTAL_DEDUCTION7 c3a_othergovt_tot_ded
  rename NET_INPATIENT_REVENUE7 c3a_othergovt_net_ip_rev
  rename NET_OUTPATIENT_REVENUE7 c3a_othergovt_net_op_rev
  rename NET_PATIENT_REVENUE7 c3a_othergovt_net_tot_rev
  
  rename INPATIENT_REVENUE8 c3a_inscharged_ip_rev
  rename OUTPATIENT_REVENUE8 c3a_inscharged_op_rev
  rename TOTAL_REVENUE8 c3a_inscharged_tot_rev
  rename INPATIENT_DEDUCTION8 c3a_inscharged_ip_ded
  rename OUTPATIENT_DEDUCTION8 c3a_inscharged_op_ded
  rename TOTAL_DEDUCTION8 c3a_inscharged_tot_ded
  rename NET_INPATIENT_REVENUE8 c3a_inscharged_net_ip_rev
  rename NET_OUTPATIENT_REVENUE8 c3a_inscharged_net_op_rev
  rename NET_PATIENT_REVENUE8 c3a_inscharged_net_tot_rev
  
  rename INPATIENT_REVENUE9 c3a_othercharged_ip_rev
  rename OUTPATIENT_REVENUE9 c3a_othercharged_op_rev
  rename TOTAL_REVENUE9 c3a_othercharged_tot_rev
  rename INPATIENT_DEDUCTION9 c3a_othercharged_ip_ded
  rename OUTPATIENT_DEDUCTION9 c3a_othercharged_op_ded
  rename TOTAL_DEDUCTION9 c3a_othercharged_tot_ded
  rename NET_INPATIENT_REVENUE9 c3a_othercharged_net_ip_rev
  rename NET_OUTPATIENT_REVENUE9 c3a_othercharged_net_op_rev
  rename NET_PATIENT_REVENUE9 c3a_othercharged_net_tot_rev
  
  rename INPATIENT_REVENUE10 c3a_medicareHMO_ip_rev
  rename OUTPATIENT_REVENUE10 c3a_medicareHMO_op_rev
  rename TOTAL_REVENUE10 c3a_medicareHMO_tot_rev
  rename INPATIENT_DEDUCTION10 c3a_medicareHMO_ip_ded
  rename OUTPATIENT_DEDUCTION10 c3a_medicareHMO_op_ded
  rename TOTAL_DEDUCTION10 c3a_medicareHMO_tot_ded
  rename NET_INPATIENT_REVENUE10 c3a_medicareHMO_net_ip_rev
  rename NET_OUTPATIENT_REVENUE10 c3a_medicareHMO_net_op_rev
  rename NET_PATIENT_REVENUE10 c3a_medicareHMO_net_tot_rev
  
  rename INPATIENT_REVENUE11 c3a_medicaidHMO_ip_rev
  rename OUTPATIENT_REVENUE11 c3a_medicaidHMO_op_rev
  rename TOTAL_REVENUE11 c3a_medicaidHMO_tot_rev
  rename INPATIENT_DEDUCTION11 c3a_medicaidHMO_ip_ded
  rename OUTPATIENT_DEDUCTION11 c3a_medicaidHMO_op_ded
  rename TOTAL_DEDUCTION11 c3a_medicaidHMO_tot_ded
  rename NET_INPATIENT_REVENUE11 c3a_medicaidHMO_net_ip_rev
  rename NET_OUTPATIENT_REVENUE11 c3a_medicaidHMO_net_op_rev
  rename NET_PATIENT_REVENUE11 c3a_medicaidHMO_net_tot_rev
  
  rename INPATIENT_REVENUE12 c3a_commHMO_ip_rev
  rename OUTPATIENT_REVENUE12 c3a_commHMO_op_rev
  rename TOTAL_REVENUE12 c3a_commHMO_tot_rev
  rename INPATIENT_DEDUCTION12 c3a_commHMO_ip_ded
  rename OUTPATIENT_DEDUCTION12 c3a_commHMO_op_ded
  rename TOTAL_DEDUCTION12 c3a_commHMO_tot_ded
  rename NET_INPATIENT_REVENUE12 c3a_commHMO_net_ip_rev
  rename NET_OUTPATIENT_REVENUE12 c3a_commHMO_net_op_rev
  rename NET_PATIENT_REVENUE12 c3a_commHMO_net_tot_rev
  
  rename INPATIENT_REVENUE13 c3a_commPPO_ip_rev
  rename OUTPATIENT_REVENUE13 c3a_commPPO_op_rev
  rename TOTAL_REVENUE13 c3a_commPPO_tot_rev
  rename INPATIENT_DEDUCTION13 c3a_commPPO_ip_ded
  rename OUTPATIENT_DEDUCTION13 c3a_commPPO_op_ded
  rename TOTAL_DEDUCTION13 c3a_commPPO_tot_ded
  rename NET_INPATIENT_REVENUE13 c3a_commPPO_net_ip_rev
  rename NET_OUTPATIENT_REVENUE13 c3a_commPPO_net_op_rev
  rename NET_PATIENT_REVENUE13 c3a_commPPO_net_tot_rev
  
  rename INPATIENT_REVENUE14 c3a_othcomm_ip_rev
  rename OUTPATIENT_REVENUE14 c3a_othcomm_op_rev
  rename TOTAL_REVENUE14 c3a_othcomm_tot_rev
  rename INPATIENT_DEDUCTION14 c3a_othcomm_ip_ded
  rename OUTPATIENT_DEDUCTION14 c3a_othcomm_op_ded
  rename TOTAL_DEDUCTION14 c3a_othcomm_tot_ded
  rename NET_INPATIENT_REVENUE14 c3a_othcomm_net_ip_rev
  rename NET_OUTPATIENT_REVENUE14 c3a_othcomm_net_op_rev
  rename NET_PATIENT_REVENUE14 c3a_othcomm_net_tot_rev
  
  rename INPATIENT_REVENUE15 c3a_admindis_ip_rev
  rename OUTPATIENT_REVENUE15 c3a_admindis_op_rev
  rename TOTAL_REVENUE15 c3a_admindis_tot_rev
  rename INPATIENT_DEDUCTION15 c3a_admindis_ip_ded
  rename OUTPATIENT_DEDUCTION15 c3a_admindis_op_ded
  rename TOTAL_DEDUCTION15 c3a_admindis_tot_ded
  rename NET_INPATIENT_REVENUE15 c3a_admindis_net_ip_rev
  rename NET_OUTPATIENT_REVENUE15 c3a_admindis_net_op_rev
  rename NET_PATIENT_REVENUE15 c3a_admindis_net_tot_rev
  
  rename INPATIENT_REVENUE16 c3a_employdis_ip_rev
  rename OUTPATIENT_REVENUE16 c3a_employdis_op_rev
  rename TOTAL_REVENUE16 c3a_employdis_tot_rev
  rename INPATIENT_DEDUCTION16 c3a_employdis_ip_ded
  rename OUTPATIENT_DEDUCTION16 c3a_employdis_op_ded
  rename TOTAL_DEDUCTION16 c3a_employdis_tot_ded
  rename NET_INPATIENT_REVENUE16 c3a_employdis_net_ip_rev
  rename NET_OUTPATIENT_REVENUE16 c3a_employdis_net_op_rev
  rename NET_PATIENT_REVENUE16 c3a_employdis_net_tot_rev
  
  rename INPATIENT_REVENUE17 c3a_otherdeduc_ip_rev
  rename OUTPATIENT_REVENUE17 c3a_otherdeduc_op_rev
  rename TOTAL_REVENUE17 c3a_otherdeduc_tot_rev
  rename INPATIENT_DEDUCTION17 c3a_otherdeduc_ip_ded
  rename OUTPATIENT_DEDUCTION17 c3a_otherdeduc_op_ded
  rename TOTAL_DEDUCTION17 c3a_otherdeduc_tot_ded
  rename NET_INPATIENT_REVENUE17 c3a_otherdeduc_net_ip_rev
  rename NET_OUTPATIENT_REVENUE17 c3a_otherdeduc_net_op_rev
  rename NET_PATIENT_REVENUE17 c3a_otherdeduc_net_tot_rev
  
  rename INPATIENT_REVENUE18 c3a_restrictfunds_ip_rev
  rename OUTPATIENT_REVENUE18 c3a_restrictfunds_op_rev
  rename TOTAL_REVENUE18 c3a_restrictfunds_tot_rev
  rename INPATIENT_DEDUCTION18 c3a_restrictfunds_ip_ded
  rename OUTPATIENT_DEDUCTION18 c3a_restrictfunds_op_ded
  rename TOTAL_DEDUCTION18 c3a_restrictfunds_tot_ded
  rename NET_INPATIENT_REVENUE18 c3a_restrictfunds_net_ip_rev
  rename NET_OUTPATIENT_REVENUE18 c3a_restrictfunds_net_op_rev
  rename NET_PATIENT_REVENUE18 c3a_restrictfunds_net_tot_rev
  
  rename INPATIENT_REVENUE19 c3a_totrevded_ip_rev
  rename OUTPATIENT_REVENUE19 c3a_totrevded_op_rev
  rename TOTAL_REVENUE19 c3a_totrevded_tot_rev
  rename INPATIENT_DEDUCTION19 c3a_totrevded_ip_ded
  rename OUTPATIENT_DEDUCTION19 c3a_totrevded_op_ded
  rename TOTAL_DEDUCTION19 c3a_totrevded_tot_ded
  rename NET_INPATIENT_REVENUE19 c3a_totrevded_net_ip_rev
  rename NET_OUTPATIENT_REVENUE19 c3a_totrevded_net_op_rev
  rename NET_PATIENT_REVENUE19 c3a_totrevded_net_tot_rev
  
  rename INPATIENT_REVENUE20 c3a_radtherapyrev_ip_rev
  rename OUTPATIENT_REVENUE20 c3a_radtherapyrev_op_rev
  rename TOTAL_REVENUE20 c3a_radtherapyrev_tot_rev
  rename INPATIENT_DEDUCTION20 c3a_radtherapyrev_ip_ded
  rename OUTPATIENT_DEDUCTION20 c3a_radtherapyrev_op_ded
  rename TOTAL_DEDUCTION20 c3a_radtherapyrev_tot_ded
  rename NET_INPATIENT_REVENUE20 c3a_radtherapyrev_net_ip_rev
  rename NET_OUTPATIENT_REVENUE20 c3a_radtherapyrev_net_op_rev
  rename NET_PATIENT_REVENUE20 c3a_radtherapyrev_net_tot_rev
  
  rename INPATIENT_REVENUE21 c3a_adjrevded_ip_rev
  rename OUTPATIENT_REVENUE21 c3a_adjrevded_op_rev
  rename TOTAL_REVENUE21 c3a_adjrevded_tot_rev
  rename INPATIENT_DEDUCTION21 c3a_adjrevded_ip_ded
  rename OUTPATIENT_DEDUCTION21 c3a_adjrevded_op_ded
  rename TOTAL_DEDUCTION21 c3a_adjrevded_tot_ded
  rename NET_INPATIENT_REVENUE21 c3a_adjrevded_net_ip_rev
  rename NET_OUTPATIENT_REVENUE21 c3a_adjrevded_net_op_rev
  rename NET_PATIENT_REVENUE21 c3a_adjrevded_net_tot_rev
  
  rename INPATIENT_REVENUE22 c3a_totHMOPPO_ip_rev
  rename OUTPATIENT_REVENUE22 c3a_totHMOPPO_op_rev
  rename TOTAL_REVENUE22 c3a_totHMOPPO_tot_rev
  rename INPATIENT_DEDUCTION22 c3a_totHMOPPO_ip_ded
  rename OUTPATIENT_DEDUCTION22 c3a_totHMOPPO_op_ded
  rename TOTAL_DEDUCTION22 c3a_totHMOPPO_tot_ded
  rename NET_INPATIENT_REVENUE22 c3a_totHMOPPO_net_ip_rev
  rename NET_OUTPATIENT_REVENUE22 c3a_totHMOPPO_net_op_rev
  rename NET_PATIENT_REVENUE22 c3a_totHMOPPO_net_tot_rev
  
  // Bad Debts (1)
  label var c3a_debt_ip_rev "Bad Debts - Total Inpatient Revenue"
  label var c3a_debt_op_rev "Bad Debts - Total Outpatient Revenue"
  label var c3a_debt_tot_rev "Bad Debts - Total Patient Revenue"
  label var c3a_debt_ip_ded "Bad Debts - Total Inpatient Deductions From Revenue"
  label var c3a_debt_op_ded "Bad Debts - Total Outpatient Dedcutions From Revenue"
  label var c3a_debt_tot_ded "Bad Debts - Total Deductions From Revenue"
  label var c3a_debt_net_ip_rev "Bad Debts - Net Inpatient Revenue"
  label var c3a_debt_net_op_rev "Bad Debts - Net Outpatient Revenue"
  label var c3a_debt_net_tot_rev "Bad Debts - Total Net Patient Revenue"
  // Self-Pay Patients (2)
  label var c3a_self_ip_rev "Self-Pay Patients - Total Inpatient Revenue"
  label var c3a_self_op_rev "Self-Pay Patients - Total Outpatient Revenue"
  label var c3a_self_tot_rev "Self-Pay Patients - Total Patient Revenue"
  label var c3a_self_ip_ded "Self-Pay Patients - Total Inpatient Deductions From Revenue"
  label var c3a_self_op_ded "Self-Pay Patients - Total Outpatient Dedcutions From Revenue"
  label var c3a_self_tot_ded "Self-Pay Patients - Total Deductions From Revenue"
  label var c3a_self_net_ip_rev "Self-Pay Patients - Net Inpatient Revenue"
  label var c3a_self_net_op_rev "Self-Pay Patients - Net Outpatient Revenue"
  label var c3a_self_net_tot_rev "Self-Pay Patients - Total Net Patient Revenue"
  // Charity Care-Hill Burton (3)
  label var c3a_charityhill_ip_rev "Charity Care-Hill Burton - Total Inpatient Revenue"
  label var c3a_charityhill_op_rev "Charity Care-Hill Burton - Total Outpatient Revenue"
  label var c3a_charityhill_tot_rev "Charity Care-Hill Burton - Total Patient Revenue"
  label var c3a_charityhill_ip_ded "Charity Care-Hill Burton - Total Inpatient Deductions From Revenue"
  label var c3a_charityhill_op_ded "Charity Care-Hill Burton - Total Outpatient Dedcutions From Revenue"
  label var c3a_charityhill_tot_ded "Charity Care-Hill Burton - Total Deductions From Revenue"
  label var c3a_charityhill_net_ip_rev "Charity Care-Hill Burton - Net Inpatient Revenue"
  label var c3a_charityhill_net_op_rev "Charity Care-Hill Burton - Net Outpatient Revenue"
  label var c3a_charityhill_net_tot_rev "Charity Care-Hill Burton - Total Net Patient Revenue"
  // Charity Care-Other (4)
  label var c3a_charityother_ip_rev "Charity Care-Other - Total Inpatient Revenue"
  label var c3a_charityother_op_rev "Charity Care-Other - Total Outpatient Revenue"
  label var c3a_charityother_tot_rev "Charity Care-Other - Total Patient Revenue"
  label var c3a_charityother_ip_ded "Charity Care-Other - Total Inpatient Deductions From Revenue"
  label var c3a_charityother_op_ded "Charity Care-Other - Total Outpatient Dedcutions From Revenue"
  label var c3a_charityother_tot_ded "Charity Care-Other - Total Deductions From Revenue"
  label var c3a_charityother_net_ip_rev "Charity Care-Other - Net Inpatient Revenue"
  label var c3a_charityother_net_op_rev "Charity Care-Other - Net Outpatient Revenue"
  label var c3a_charityother_net_tot_rev "Charity Care-Other - Total Net Patient Revenue"
  // Conventional-Medicare (5)
  label var c3a_convmedicare_ip_rev "Conventional-Medicare - Total Inpatient Revenue"
  label var c3a_convmedicare_op_rev "Conventional-Medicare - Total Outpatient Revenue"
  label var c3a_convmedicare_tot_rev "Conventional-Medicare - Total Patient Revenue"
  label var c3a_convmedicare_ip_ded "Conventional-Medicare - Total Inpatient Deductions From Revenue"
  label var c3a_convmedicare_op_ded "Conventional-Medicare - Total Outpatient Dedcutions From Revenue"
  label var c3a_convmedicare_tot_ded "Conventional-Medicare - Total Deductions From Revenue"
  label var c3a_convmedicare_net_ip_rev "Conventional-Medicare - Net Inpatient Revenue"
  label var c3a_convmedicare_net_op_rev "Conventional-Medicare - Net Outpatient Revenue"
  label var c3a_convmedicare_net_tot_rev "Conventional-Medicare - Total Net Patient Revenue"
  // Conventional-Medicaid (6)
  label var c3a_convmedicaid_ip_rev "Conventional-Medicaid - Total Inpatient Revenue"
  label var c3a_convmedicaid_op_rev "Conventional-Medicaid - Total Outpatient Revenue"
  label var c3a_convmedicaid_tot_rev "Conventional-Medicaid - Total Patient Revenue"
  label var c3a_convmedicaid_ip_ded "Conventional-Medicaid - Total Inpatient Deductions From Revenue"
  label var c3a_convmedicaid_op_ded "Conventional-Medicaid - Total Outpatient Dedcutions From Revenue"
  label var c3a_convmedicaid_tot_ded "Conventional-Medicaid - Total Deductions From Revenue"
  label var c3a_convmedicaid_net_ip_rev "Conventional-Medicaid - Net Inpatient Revenue"
  label var c3a_convmedicaid_net_op_rev "Conventional-Medicaid - Net Outpatient Revenue"
  label var c3a_convmedicaid_net_tot_rev "Conventional-Medicaid - Total Net Patient Revenue"
  // Other Government Fixed-Price Payors (7)
  label var c3a_othergovt_ip_rev "Other Govt Fixed-Price Payors - Total Inpatient Revenue"
  label var c3a_othergovt_op_rev "Other Govt Fixed-Price Payors- Total Outpatient Revenue"
  label var c3a_othergovt_tot_rev "Other Govt Fixed-Price Payors - Total Patient Revenue"
  label var c3a_othergovt_ip_ded "Other Govt Fixed-Price Payors - Total Inpatient Deductions From Revenue"
  label var c3a_othergovt_op_ded "Other Govt Fixed-Price Payors - Total Outpatient Dedcutions From Revenue"
  label var c3a_othergovt_tot_ded "Other Govt Fixed-Price Payors - Total Deductions From Revenue"
  label var c3a_othergovt_net_ip_rev "Other Govt Fixed-Price Payors - Net Inpatient Revenue"
  label var c3a_othergovt_net_op_rev "Other Govt Fixed-Price Payors - Net Outpatient Revenue"
  label var c3a_othergovt_net_tot_rev "Other Govt Fixed-Price Payors - Total Net Patient Revenue"
  // Insurance Charge-Based (8)
  label var c3a_inscharged_ip_rev "Insurance Charge-Based - Total Inpatient Revenue"
  label var c3a_inscharged_op_rev "Insurance Charge-Based - Total Outpatient Revenue"
  label var c3a_inscharged_tot_rev "Insurance Charge-Based - Total Patient Revenue"
  label var c3a_inscharged_ip_ded "Insurance Charge-Based - Total Inpatient Deductions From Revenue"
  label var c3a_inscharged_op_ded "Insurance Charge-Based - Total Outpatient Dedcutions From Revenue"
  label var c3a_inscharged_tot_ded "Insurance Charge-Based - Total Deductions From Revenue"
  label var c3a_inscharged_net_ip_rev "Insurance Charge-Based - Net Inpatient Revenue"
  label var c3a_inscharged_net_op_rev "Insurance Charge-Based - Net Outpatient Revenue"
  label var c3a_inscharged_net_tot_rev "Insurance Charge-Based - Total Net Patient Revenue"
  // Other Charge Based Payors (9)
  label var c3a_othercharged_ip_rev "Other Charge Based Payors - Total Inpatient Revenue"
  label var c3a_othercharged_op_rev "Other Charge Based Payors - Total Outpatient Revenue"
  label var c3a_othercharged_tot_rev "Other Charge Based Payors - Total Patient Revenue"
  label var c3a_othercharged_ip_ded "Other Charge Based Payors - Total Inpatient Deductions From Revenue"
  label var c3a_othercharged_op_ded "Other Charge Based Payors - Total Outpatient Dedcutions From Revenue"
  label var c3a_othercharged_tot_ded "Other Charge Based Payors - Total Deductions From Revenue"
  label var c3a_othercharged_net_ip_rev "Other Charge Based Payors - Net Inpatient Revenue"
  label var c3a_othercharged_net_op_rev "Other Charge Based Payors - Net Outpatient Revenue"
  label var c3a_othercharged_net_tot_rev "Other Charge Based Payors - Total Net Patient Revenue"
  // Medicare-HMO (10)
  label var c3a_medicareHMO_ip_rev "Medicare-HMO - Total Inpatient Revenue"
  label var c3a_medicareHMO_op_rev "Medicare-HMO - Total Outpatient Revenue"
  label var c3a_medicareHMO_tot_rev "Medicare-HMO - Total Patient Revenue"
  label var c3a_medicareHMO_ip_ded "Medicare-HMO - Total Inpatient Deductions From Revenue"
  label var c3a_medicareHMO_op_ded "Medicare-HMO - Total Outpatient Dedcutions From Revenue"
  label var c3a_medicareHMO_tot_ded "Medicare-HMO - Total Deductions From Revenue"
  label var c3a_medicareHMO_net_ip_rev "Medicare-HMO - Net Inpatient Revenue"
  label var c3a_medicareHMO_net_op_rev "Medicare-HMO - Net Outpatient Revenue"
  label var c3a_medicareHMO_net_tot_rev "Medicare-HMO - Total Net Patient Revenue"
  // Medicaid-HMO (11)
  label var c3a_medicaidHMO_ip_rev "Medicaid-HMO - Total Inpatient Revenue"
  label var c3a_medicaidHMO_op_rev "Medicaid-HMO- Total Outpatient Revenue"
  label var c3a_medicaidHMO_tot_rev "Medicaid-HMO - Total Patient Revenue"
  label var c3a_medicaidHMO_ip_ded "Medicaid-HMO - Total Inpatient Deductions From Revenue"
  label var c3a_medicaidHMO_op_ded "Medicaid-HMO - Total Outpatient Dedcutions From Revenue"
  label var c3a_medicaidHMO_tot_ded "Medicaid-HMO - Total Deductions From Revenue"
  label var c3a_medicaidHMO_net_ip_rev "Medicaid-HMO - Net Inpatient Revenue"
  label var c3a_medicaidHMO_net_op_rev "Medicaid-HMO - Net Outpatient Revenue"
  label var c3a_medicaidHMO_net_tot_rev "Medicaid-HMO - Total Net Patient Revenue"
  // Commercial-HMO (12)
  label var c3a_commHMO_ip_rev "Commercial-HMO  - Total Inpatient Revenue"
  label var c3a_commHMO_op_rev "Commercial-HMO - Total Outpatient Revenue"
  label var c3a_commHMO_tot_rev "Commercial-HMO - Total Patient Revenue"
  label var c3a_commHMO_ip_ded "Commercial-HMO - Total Inpatient Deductions From Revenue"
  label var c3a_commHMO_op_ded "Commercial-HMO - Total Outpatient Dedcutions From Revenue"
  label var c3a_commHMO_tot_ded "Commercial-HMO - Total Deductions From Revenue"
  label var c3a_commHMO_net_ip_rev "Commercial-HMO - Net Inpatient Revenue"
  label var c3a_commHMO_net_op_rev "Commercial-HMO - Net Outpatient Revenue"
  label var c3a_commHMO_net_tot_rev "Commercial-HMO - Total Net Patient Revenue"
  // Commercial-PPO (13)
  label var c3a_commPPO_ip_rev "Commercial-PPO  - Total Inpatient Revenue"
  label var c3a_commPPO_op_rev "Commercial-PPO - Total Outpatient Revenue"
  label var c3a_commPPO_tot_rev "Commercial-PPO - Total Patient Revenue"
  label var c3a_commHMO_ip_ded "Commercial-PPO - Total Inpatient Deductions From Revenue"
  label var c3a_commPPO_op_ded "Commercial-PPO - Total Outpatient Dedcutions From Revenue"
  label var c3a_commPPO_tot_ded "Commercial-PPO - Total Deductions From Revenue"
  label var c3a_commPPO_net_ip_rev "Commercial-PPO - Net Inpatient Revenue"
  label var c3a_commPPO_net_op_rev "Commercial-PPO - Net Outpatient Revenue"
  label var c3a_commPPO_net_tot_rev "Commercial-PPO - Total Net Patient Revenue"
  // Other Commercial Discounted Payors (14)
  label var c3a_othcomm_ip_rev "Other Commercial Discounted Payors  - Total Inpatient Revenue"
  label var c3a_othcomm_op_rev "Other Commercial Discounted Payors - Total Outpatient Revenue"
  label var c3a_othcomm_tot_rev "Other Commercial Discounted Payors - Total Patient Revenue"
  label var c3a_othcomm_ip_ded "Other Commercial Discounted Payors - Total Inpatient Deductions From Revenue"
  label var c3a_othcomm_op_ded "Other Commercial Discounted Payors - Total Outpatient Dedcutions From Revenue"
  label var c3a_othcomm_tot_ded "Other Commercial Discounted Payors - Total Deductions From Revenue"
  label var c3a_othcomm_net_ip_rev "Other Commercial Discounted Payors - Net Inpatient Revenue"
  label var c3a_othcomm_net_op_rev "Other Commercial Discounted Payors - Net Outpatient Revenue"
  label var c3a_othcomm_net_tot_rev "Other Commercial Discounted Payors - Total Net Patient Revenue"
  // Admin. Courtesy and Policy Discounts (15)
  label var c3a_admindis_ip_rev "Admin. Courtesy and Policy Discounts  - Total Inpatient Revenue"
  label var c3a_admindis_op_rev "Admin. Courtesy and Policy Discounts - Total Outpatient Revenue"
  label var c3a_admindis_tot_rev "Admin. Courtesy and Policy Discounts - Total Patient Revenue"
  label var c3a_admindis_ip_ded "Admin. Courtesy and Policy Discounts - Total Inpatient Deductions From Revenue"
  label var c3a_admindis_op_ded "Admin. Courtesy and Policy Discounts - Total Outpatient Dedcutions From Revenue"
  label var c3a_admindis_tot_ded "Admin. Courtesy and Policy Discounts - Total Deductions From Revenue"
  label var c3a_admindis_net_ip_rev "Admin. Courtesy and Policy Discounts - Net Inpatient Revenue"
  label var c3a_admindis_net_op_rev "Admin. Courtesy and Policy Discounts - Net Outpatient Revenue"
  label var c3a_admindis_net_tot_rev "Admin. Courtesy and Policy Discounts - Total Net Patient Revenue"
  // Employee Discounts (16);
  label var c3a_employdis_ip_rev "Employee Discounts  - Total Inpatient Revenue"
  label var c3a_employdis_op_rev "Employee Discounts - Total Outpatient Revenue"
  label var c3a_employdis_tot_rev "Employee Discounts - Total Patient Revenue"
  label var c3a_employdis_ip_ded "Employee Discounts - Total Inpatient Deductions From Revenue"
  label var c3a_employdis_op_ded "Employee Discounts - Total Outpatient Dedcutions From Revenue"
  label var c3a_employdis_tot_ded "Employee Discounts - Total Deductions From Revenue"
  label var c3a_employdis_net_ip_rev "Employee Discounts - Net Inpatient Revenue"
  label var c3a_employdis_net_op_rev "Employee Discounts - Net Outpatient Revenue"
  label var c3a_employdis_net_tot_rev "Employee Discounts - Total Net Patient Revenue"
  // Other Deductions from Revenue (17)
  label var c3a_otherdeduc_ip_rev "Other Deductions from Revenue  - Total Inpatient Revenue"
  label var c3a_otherdeduc_op_rev "Other Deductions from Revenue - Total Outpatient Revenue"
  label var c3a_otherdeduc_tot_rev "Other Deductions from Revenue - Total Patient Revenue"
  label var c3a_otherdeduc_ip_ded "Other Deductions from Revenue - Total Inpatient Deductions From Revenue"
  label var c3a_otherdeduc_op_ded "Other Deductions from Revenue - Total Outpatient Dedcutions From Revenue"
  label var c3a_otherdeduc_tot_ded "Other Deductions from Revenue - Total Deductions From Revenue"
  label var c3a_otherdeduc_net_ip_rev "Other Deductions from Revenue - Net Inpatient Revenue"
  label var c3a_otherdeduc_net_op_rev "Other Deductions from Revenue - Net Outpatient Revenue"
  label var c3a_otherdeduc_net_tot_rev "Other Deductions from Revenue - Total Net Patient Revenue"
  // Restricted Funds for Indigent Care (18)
  label var c3a_restrictfunds_ip_rev "Restricted Funds for Indigent Care  - Total Inpatient Revenue"
  label var c3a_restrictfunds_op_rev "Restricted Funds for Indigent Care - Total Outpatient Revenue"
  label var c3a_restrictfunds_tot_rev "Restricted Funds for Indigent Care - Total Patient Revenue"
  label var c3a_restrictfunds_ip_ded "Restricted Funds for Indigent Care - Total Inpatient Deductions From Revenue"
  label var c3a_restrictfunds_op_ded "Restricted Funds for Indigent Care - Total Outpatient Dedcutions From Revenue"
  label var c3a_restrictfunds_tot_ded "Restricted Funds for Indigent Care - Total Deductions From Revenue"
  label var c3a_restrictfunds_net_ip_rev "Restricted Funds for Indigent Care - Net Inpatient Revenue"
  label var c3a_restrictfunds_net_op_rev "Restricted Funds for Indigent Care - Net Outpatient Revenue"
  label var c3a_restrictfunds_net_tot_rev "Restricted Funds for Indigent Care - Total Net Patient Revenue"

  // Total Revenue and Deductions (19)
  label var c3a_totrevded_ip_rev "Total Revenue and Deductions - Total Inpatient Revenue"
  label var c3a_totrevded_op_rev "Total Revenue and Deductions - Total Outpatient Revenue"
  label var c3a_totrevded_tot_rev "Total Revenue and Deductions - Total Patient Revenue"
  label var c3a_totrevded_ip_ded "Total Revenue and Deductions - Total Inpatient Deductions From Revenue"
  label var c3a_totrevded_op_ded "Total Revenue and Deductions - Total Outpatient Dedcutions From Revenue"
  label var c3a_totrevded_tot_ded "Total Revenue and Deductions - Total Deductions From Revenue"
  label var c3a_totrevded_net_ip_rev "Total Revenue and Deductions - Net Inpatient Revenue"
  label var c3a_totrevded_net_op_rev "Total Revenue and Deductions - Net Outpatient Revenue"
  label var c3a_totrevded_net_tot_rev "Total Revenue and Deductions - Total Net Patient Revenue"
  // Radiation Therapy Revenue (20)
  label var c3a_radtherapyrev_ip_rev "Radiation Therapy Revenue - Total Inpatient Revenue"
  label var c3a_radtherapyrev_op_rev "Radiation Therapy Revenue - Total Outpatient Revenue"
  label var c3a_radtherapyrev_tot_rev "Radiation Therapy Revenue - Total Patient Revenue"
  label var c3a_radtherapyrev_ip_ded "Radiation Therapy Revenue - Total Inpatient Deductions From Revenue"
  label var c3a_radtherapyrev_op_ded "Radiation Therapy Revenue - Total Outpatient Dedcutions From Revenue"
  label var c3a_radtherapyrev_tot_ded "Radiation Therapy Revenue - Total Deductions From Revenue"
  label var c3a_radtherapyrev_net_ip_rev "Radiation Therapy Revenue - Net Inpatient Revenue"
  label var c3a_radtherapyrev_net_op_rev "Radiation Therapy Revenue - Net Outpatient Revenue"
  label var c3a_radtherapyrev_net_tot_rev "Radiation Therapy Revenue - Total Net Patient Revenue"
  // Adjusted Revenue And Deductions (21)
  label var c3a_adjrevded_ip_rev "Adjusted Revenue And Deductions - Total Inpatient Revenue"
  label var c3a_adjrevded_op_rev "Adjusted Revenue And Deductions - Total Outpatient Revenue"
  label var c3a_adjrevded_tot_rev "Adjusted Revenue And Deductions - Total Patient Revenue"
  label var c3a_adjrevded_ip_ded "Adjusted Revenue And Deductions - Total Inpatient Deductions From Revenue"
  label var c3a_adjrevded_op_ded "Adjusted Revenue And Deductions - Total Outpatient Dedcutions From Revenue"
  label var c3a_adjrevded_tot_ded "Adjusted Revenue And Deductions - Total Deductions From Revenue"
  label var c3a_adjrevded_net_ip_rev "Adjusted Revenue And Deductions - Net Inpatient Revenue"
  label var c3a_adjrevded_net_op_rev "Adjusted Revenue And Deductions - Net Outpatient Revenue"
  label var c3a_adjrevded_net_tot_rev "Adjusted Revenue And Deductions - Total Net Patient Revenue"
  // Total HMO/PPO Payment (22)
  label var c3a_totHMOPPO_ip_rev "Total HMO/PPO Payment - Total Inpatient Revenue"
  label var c3a_totHMOPPO_op_rev "Total HMO/PPO Payment - Total Outpatient Revenue"
  label var c3a_totHMOPPO_tot_rev "Total HMO/PPO Payment - Total Patient Revenue"
  label var c3a_totHMOPPO_ip_ded "Total HMO/PPO Payment - Total Inpatient Deductions From Revenue"
  label var c3a_totHMOPPO_op_ded "Total HMO/PPO Payment - Total Outpatient Dedcutions From Revenue"
  label var c3a_totHMOPPO_tot_ded "Total HMO/PPO Payment - Total Deductions From Revenue"
  label var c3a_totHMOPPO_net_ip_rev "Total HMO/PPO Payment - Net Inpatient Revenue"
  label var c3a_totHMOPPO_net_op_rev "Total HMO/PPO Payment - Net Outpatient Revenue"
  label var c3a_totHMOPPO_net_tot_rev "Total HMO/PPO Payment - Total Net Patient Revenue"

* 7. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check
  
* 8. Save
  save ${sheets}fl_`i'_C3a.dta, replace
  clear
  
}




*===============================================================================
* 7. Extract C-4 info - STATEMENT OF OTHER OPERATING AND NONOPERATING REVENUE
*===============================================================================


forvalues i=2004(1)2020 {

* 1. Import C4 sheet 
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_C4") firstrow allstring clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Pick the most recent record per hospital
  generate latest_date=date(report_from,"MDY")
  bysort FILE_NBR: egen max_date=max(latest_date)
  keep if max_date==latest_date
  drop max_date latest_date

* 4. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"
 
* 5. Drop duplicate hospital observations
  // Each hospital has multiple rows and each row is a different variable  
  bysort FILE_NBR LINE_NUMBER: ge N=_N
  tabulate N
  bysort FILE_NBR LINE_NUMBER: drop if _n>1

* 6. Drop unnecessary variables
  drop CLIENT_CODE N SUBMISSION_NUMBER report_to report_from

* 7. Reshape Data
  // Reshape data such that each hospital has one row and multiple column variables
  destring LINE_NUMBER, force replace 
  reshape wide AMOUNT, i(FILE_NBR) j(LINE_NUMBER)
  describe // Data Check
  summarize // Data Check

* 8. Keep relevant variables 
  keep FILE_NBR AMOUNT2 AMOUNT3 AMOUNT4 AMOUNT5
  describe // Data Check

* 9. Renaming & labeling variables 
  rename FILE_NBR faclnbr

  rename AMOUNT2 c4_nursinged 
  rename AMOUNT3 c4_apstgraded	
  rename AMOUNT4 c4_npstgraded	
  rename AMOUNT5 c4_othealthed	

  label var c4_nursinged "revenue from Nursing Education"
  label var c4_apstgraded "revenue from Approved Post Graduate Medical Education"
  label var c4_npstgraded "revenue from Nonapproved Post Graduate Medical Education"
  label var c4_othealthed "revenue from Allied Health Programs"

  
* 10. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check
  list in 1/10

* 11. Save
  save ${sheets}fl_`i'_C4.dta, replace
  clear
 
 
}


*===============================================================================
* 8. Extract C-5 info - STATEMENT OF PATIENT CARE SERVICES EXPENSE
*===============================================================================
  
forvalues i=2004(1)2020 {

* 1. Import C-5 sheet 
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_C5") firstrow allstring  clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"

* 4. Drop duplicate hospital observations
  // Each hospital has multiple rows and each row is a different variable  
  foreach x of varlist SALARY_WAGE-FTE {
  destring `x', force replace
  }
  collapse (sum) SALARY_WAGE-FTE, by(FILE_NBR LINE_NUMBER)
  bysort FILE_NBR LINE_NUMBER: ge N=_N
  tabulate N
  bysort FILE_NBR LINE_NUMBER: drop if _n>1

* 5. Reshape Data
  // Reshape data such that each hospital has one row and multiple column variables
  drop if LINE_NUMBER== "03a"
  destring LINE_NUMBER, force replace 
  reshape wide SALARY_WAGE-FTE, i(FILE_NBR) j(LINE_NUMBER)
  describe // Data Check
  summarize // Data Check 
 
* 6. Renaming & labeling variables 
  rename FILE_NBR faclnbr
 
   
  rename SALARY_WAGE20 c5_swtotdly
  rename SALARY_WAGE21 c5_swemerge
  rename SALARY_WAGE22 c5_swclinic
  rename SALARY_WAGE27 c5_swfreest
  rename SALARY_WAGE29 c5_swtotamb
  rename SALARY_WAGE39 c5_swelectr
  rename SALARY_WAGE40 c5_swcardia
  rename SALARY_WAGE41 c5_swradiol
  rename SALARY_WAGE42 c5_swtomogr
  rename SALARY_WAGE43 c5_swmagres
  rename SALARY_WAGE44 c5_swtherap
  rename SALARY_WAGE45 c5_swnuclea
  rename SALARY_WAGE46 c5_swrespir
  rename SALARY_WAGE53 c5_swtotanc
  rename SALARY_WAGE54 c5_swtotals

  rename OTHER_EXPENSE20 c5_othexptotdly
  rename OTHER_EXPENSE21 c5_othexpemerge
  rename OTHER_EXPENSE22 c5_othexpclinic
  rename OTHER_EXPENSE27 c5_othexpfreest
  rename OTHER_EXPENSE29 c5_othexptotamb
  rename OTHER_EXPENSE39 c5_othexpelectr
  rename OTHER_EXPENSE40 c5_othexpcardia
  rename OTHER_EXPENSE41 c5_othexpradiol
  rename OTHER_EXPENSE42 c5_othexptomogr
  rename OTHER_EXPENSE43 c5_othexpmagres
  rename OTHER_EXPENSE44 c5_othexptherap
  rename OTHER_EXPENSE45 c5_othexpnuclea
  rename OTHER_EXPENSE46 c5_othexprespir
  rename OTHER_EXPENSE53 c5_othexptotanc
  rename OTHER_EXPENSE54 c5_othexptotals

  rename TOTAL_EXPENSE20 c5_totexptotdly
  rename TOTAL_EXPENSE21 c5_totexpemerge
  rename TOTAL_EXPENSE22 c5_totexpclinic
  rename TOTAL_EXPENSE27 c5_totexpfreest
  rename TOTAL_EXPENSE29 c5_totexptotamb
  rename TOTAL_EXPENSE39 c5_totexpelectr
  rename TOTAL_EXPENSE40 c5_totexpcardia
  rename TOTAL_EXPENSE41 c5_totexpradiol
  rename TOTAL_EXPENSE42 c5_totexptomogr
  rename TOTAL_EXPENSE43 c5_totexpmagres
  rename TOTAL_EXPENSE44 c5_totexptherap
  rename TOTAL_EXPENSE45 c5_totexpnuclea
  rename TOTAL_EXPENSE46 c5_totexprespir
  rename TOTAL_EXPENSE53 c5_totexptotanc
  rename TOTAL_EXPENSE54 c5_totexptotals

  rename FTE20 c5_ftetotdly
  rename FTE21 c5_fteemerge
  rename FTE22 c5_fteclinic
  rename FTE27 c5_ftefreest
  rename FTE29 c5_ftetotamb
  rename FTE39 c5_fteelectr
  rename FTE40 c5_ftecardia
  rename FTE41 c5_fteradiol
  rename FTE42 c5_ftetomogr
  rename FTE43 c5_ftemagres
  rename FTE44 c5_ftetherap
  rename FTE45 c5_ftenuclea
  rename FTE46 c5_fterespir
  rename FTE53 c5_ftetotanc
  rename FTE54 c5_ftetotals

  // DAILY HOSPITAL SERVICES
  label var c5_swtotdly "c5 - salaries expense - Total Daily Hospital Services (Lines 1 through 19)"
  // AMBULATORY SERVICES
  label var c5_swemerge "c5 - salaries expense - Emergency Services"
  label var c5_swclinic "c5 - salaries expense - Clinic Services"  
  label var c5_swfreest "c5 - salaries expense - Free Standing Clinic" 
  label var c5_swtotamb "c5 - salaries expense - Total Ambulatory Services (Lines 21 through 28)"   
  // ANCILLARY SERVICES
  label var c5_swelectr "c5 - salaries expense - Electrocardiography (ECG)"
  label var c5_swcardia "c5 - salaries expense - Cardiac Catherterization"  
  label var c5_swradiol "c5 - salaries expense - Radiology/ Diagnostic" 
  label var c5_swtomogr "c5 - salaries expense - Computerized Tomography (CT)" 
  label var c5_swmagres "c5 - salaries expense - Magnetic Resonance Imaging (MRI)"  
  label var c5_swtherap "c5 - salaries expense - Radiology / Therapeutic"  
  label var c5_swnuclea "c5 - salaries expense - Nuclear Medicine"  
  label var c5_swrespir "c5 - salaries expense - Respiratory Therapy"  
  label var c5_swtotanc "c5 - salaries expense - Total Ancillary Services (Lines 30 through 52)"  
  label var c5_swtotals "c5 - salaries expense - Total Patient Care Services (Lines 20, 29 & 53)" 

  // DAILY HOSPITAL SERVICES
  label var c5_othexptotdly "c5 - other expense - Total Daily Hospital Services (Lines 1 through 19)"
  // AMBULATORY SERVICES
  label var c5_othexpemerge "c5 - other expense - Emergency Services"
  label var c5_othexpclinic "c5 - other expense - Clinic Services"  
  label var c5_othexpfreest "c5 - other expense - Free Standing Clinic" 
  label var c5_othexptotamb "c5 - other expense - Total Ambulatory Services (Lines 21 through 28)"   
  // ANCILLARY SERVICES
  label var c5_othexpelectr "c5 - other expense - Electrocardiography (ECG)"
  label var c5_othexpcardia "c5 - other expense - Cardiac Catherterization"  
  label var c5_othexpradiol "c5 - other expense - Radiology/ Diagnostic" 
  label var c5_othexptomogr "c5 - other expense - Computerized Tomography (CT)" 
  label var c5_othexpmagres "c5 - other expense - Magnetic Resonance Imaging (MRI)"  
  label var c5_othexptherap "c5 - other expense - Radiology / Therapeutic"  
  label var c5_othexpnuclea "c5 - other expense - Nuclear Medicine"  
  label var c5_othexprespir "c5 - other expense - Respiratory Therapy"  
  label var c5_othexptotanc "c5 - other expense - Total Ancillary Services (Lines 30 through 52)"  
  label var c5_othexptotals "c5 - other expense - Total Patient Care Services (Lines 20, 29 & 53)" 

  // DAILY HOSPITAL SERVICES
  label var c5_totexptotdly "c5 - total expense - Total Daily Hospital Services (Lines 1 through 19)"
  // AMBULATORY SERVICES
  label var c5_totexpemerge "c5 - total expense - Emergency Services"
  label var c5_totexpclinic "c5 - total expense - Clinic Services"  
  label var c5_totexpfreest "c5 - total expense - Free Standing Clinic" 
  label var c5_totexptotamb "c5 - total expense - Total Ambulatory Services (Lines 21 through 28)"   
  // ANCILLARY SERVICES
  label var c5_totexpelectr "c5 - total expense - Electrocardiography (ECG)"
  label var c5_totexpcardia "c5 - total expense - Cardiac Catherterization"  
  label var c5_totexpradiol "c5 - total expense - Radiology/ Diagnostic" 
  label var c5_totexptomogr "c5 - total expense - Computerized Tomography (CT)" 
  label var c5_totexpmagres "c5 - total expense - Magnetic Resonance Imaging (MRI)"  
  label var c5_totexptherap "c5 - total expense - Radiology / Therapeutic"  
  label var c5_totexpnuclea "c5 - total expense - Nuclear Medicine"  
  label var c5_totexprespir "c5 - total expense - Respiratory Therapy"  
  label var c5_totexptotanc "c5 - total expense - Total Ancillary Services (Lines 30 through 52)"  
  label var c5_totexptotals "c5 - total expense - Total Patient Care Services (Lines 20, 29 & 53)" 

  // DAILY HOSPITAL SERVICES
  label var c5_ftetotdly "c5 - FTE - Total Daily Hospital Services (Lines 1 through 19)"
  // AMBULATORY SERVICES
  label var c5_fteemerge "c5 - FTE - Emergency Services"
  label var c5_fteclinic "c5 - FTE - Clinic Services"  
  label var c5_ftefreest "c5 - FTE - Free Standing Clinic"  
  label var c5_ftetotamb "c5 - FTE - Total Ambulatory Services (Lines 21 through 28)"   
  // ANCILLARY SERVICES
  label var c5_fteelectr "c5 - FTE - Electrocardiography (ECG)"
  label var c5_ftecardia "c5 - FTE - Cardiac Catherterization"  
  label var c5_fteradiol "c5 - FTE - Radiology/ Diagnostic" 
  label var c5_ftetomogr "c5 - FTE - Computerized Tomography (CT)" 
  label var c5_ftemagres "c5 - FTE - Magnetic Resonance Imaging (MRI)"  
  label var c5_ftetherap "c5 - FTE - Radiology / Therapeutic"  
  label var c5_ftenuclea "c5 - FTE - Nuclear Medicine"  
  label var c5_fterespir "c5 - FTE - Respiratory Therapy"  
  label var c5_ftetotanc "c5 - FTE - Total Ancillary Services (Lines 30 through 52)"  
  label var c5_ftetotals "c5 - FTE - Total Patient Care Services (Lines 20, 29 & 53)"  
  
* 7. Drop remaining variables
  drop SALARY_WAGE*
  drop OTHER_EXPENSE*
  drop TOTAL_EXPENSE*
  drop FTE*
  drop N
  
* 8. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check
  
* 9. Save
  save ${sheets}fl_`i'_C5.dta, replace
  clear
}
  


*===============================================================================
* 9. Extract C-6 info - STATEMENT OF OTHER OPERATING AND NONOPERATING EXPENSE
*===============================================================================


forvalues i=2004(1)2020 {

* 1. Import C-6 sheet 
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_C6") firstrow allstring  clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"

* 4. Drop duplicate hospital observations
  // Each hospital has multiple rows and each row is a different variable  
  foreach x of varlist SALARY_WAGE-FTE {
  destring `x', force replace
  }
  collapse (sum) SALARY_WAGE-FTE, by(FILE_NBR LINE_NUMBER)
  bysort FILE_NBR LINE_NUMBER: ge N=_N
  tabulate N
  bysort FILE_NBR LINE_NUMBER: drop if _n>1
    
* 5. Reshape Data
  // Reshape data such that each hospital has one row and multiple column variables
  drop if LINE_NUMBER== "30a"
  drop if LINE_NUMBER== "30b"
  drop if LINE_NUMBER== "34a" // otherwise cannot destrings
  destring LINE_NUMBER, force replace 
  reshape wide SALARY_WAGE-FTE, i(FILE_NBR) j(LINE_NUMBER)
  describe // Data Check
  summarize // Data Check 

* 6. Renaming & labeling variables 
  rename FILE_NBR faclnbr

  rename SALARY_WAGE1 c6_swresearexp
  rename SALARY_WAGE2 c6_swnurgsed
  rename SALARY_WAGE3 c6_swapstgraded
  rename SALARY_WAGE4 c6_swnpstgraded
  rename SALARY_WAGE5 c6_swalliedhed
  rename SALARY_WAGE17 c6_swcentradm
  rename SALARY_WAGE18 c6_swpharmadm
  rename SALARY_WAGE19 c6_swgenrlacc
  rename SALARY_WAGE20 c6_swpatntacc
  rename SALARY_WAGE21 c6_swhosptadm
  rename SALARY_WAGE22 c6_swdataproc
  rename SALARY_WAGE23 c6_swpurchsto
  rename SALARY_WAGE24 c6_swmdrecord
  rename SALARY_WAGE25 c6_swmedstadm
  rename SALARY_WAGE26 c6_swmedstaff
  rename SALARY_WAGE27 c6_swmedcarer
  rename SALARY_WAGE28 c6_swnursgadm
  rename SALARY_WAGE29 c6_swfundrais
  rename SALARY_WAGE31 c6_swemplben
  rename SALARY_WAGE32 c6_swinsumalp
  rename SALARY_WAGE33 c6_swinsother

  rename OTHER_EXPENSE1 c6_othresearexp
  rename OTHER_EXPENSE2 c6_othnurgsed
  rename OTHER_EXPENSE3 c6_othapstgraded
  rename OTHER_EXPENSE4 c6_othnpstgraded
  rename OTHER_EXPENSE5 c6_othalliedhed
  rename OTHER_EXPENSE17 c6_othcentradm
  rename OTHER_EXPENSE18 c6_othpharmadm
  rename OTHER_EXPENSE19 c6_othgenrlacc
  rename OTHER_EXPENSE20 c6_othpatntacc
  rename OTHER_EXPENSE21 c6_othhosptadm
  rename OTHER_EXPENSE22 c6_othdataproc
  rename OTHER_EXPENSE23 c6_othpurchsto
  rename OTHER_EXPENSE24 c6_othmdrecord
  rename OTHER_EXPENSE25 c6_othmedstadm
  rename OTHER_EXPENSE26 c6_othmedstaff
  rename OTHER_EXPENSE27 c6_othmedcarer
  rename OTHER_EXPENSE28 c6_othnursgadm
  rename OTHER_EXPENSE29 c6_othfundrais
  rename OTHER_EXPENSE31 c6_othemplben
  rename OTHER_EXPENSE32 c6_othinsumalp
  rename OTHER_EXPENSE33 c6_othinsother

  rename TOTAL_EXPENSE1 c6_totresearexp
  rename TOTAL_EXPENSE2 c6_totnurgsed
  rename TOTAL_EXPENSE3 c6_totapstgraded
  rename TOTAL_EXPENSE4 c6_totnpstgraded
  rename TOTAL_EXPENSE5 c6_totalliedhed
  rename TOTAL_EXPENSE17 c6_totcentradm
  rename TOTAL_EXPENSE18 c6_totpharmadm
  rename TOTAL_EXPENSE19 c6_totgenrlacc
  rename TOTAL_EXPENSE20 c6_totpatntacc
  rename TOTAL_EXPENSE21 c6_tothosptadm
  rename TOTAL_EXPENSE22 c6_totdataproc
  rename TOTAL_EXPENSE23 c6_totpurchsto
  rename TOTAL_EXPENSE24 c6_totmdrecord
  rename TOTAL_EXPENSE25 c6_totmedstadm
  rename TOTAL_EXPENSE26 c6_totmedstaff
  rename TOTAL_EXPENSE27 c6_totmedcarer
  rename TOTAL_EXPENSE28 c6_totnursgadm
  rename TOTAL_EXPENSE29 c6_totfundrais
  rename TOTAL_EXPENSE31 c6_totemplben
  rename TOTAL_EXPENSE32 c6_totinsumalp
  rename TOTAL_EXPENSE33 c6_totinsother

  rename FTE1 c6_fteresearexp
  rename FTE2 c6_ftenurgsed
  rename FTE3 c6_fteapstgraded
  rename FTE4 c6_ftenpstgraded
  rename FTE5 c6_ftealliedhed
  rename FTE17 c6_ftecentradm
  rename FTE18 c6_ftepharmadm
  rename FTE19 c6_ftegenrlacc
  rename FTE20 c6_ftepatntacc
  rename FTE21 c6_ftehosptadm
  rename FTE22 c6_ftedataproc
  rename FTE23 c6_ftepurchsto
  rename FTE24 c6_ftemdrecord
  rename FTE25 c6_ftemedstadm
  rename FTE26 c6_ftemedstaff
  rename FTE27 c6_ftemedcarer
  rename FTE28 c6_ftenursgadm
  rename FTE29 c6_ftefundrais
  rename FTE31 c6_fteemplben
  rename FTE32 c6_fteinsumalp
  rename FTE33 c6_fteinsother

  label var c6_swresearexp "c6 - salaries expense - Research Expense"
  label var c6_swnurgsed "c6 - salaries expense - Nursing Education"
  label var c6_swapstgraded "c6 - salaries expense - Approved Graduate Medical Education Program"
  label var c6_swnpstgraded "c6 - salaries expense - Nonapproved Graduate Medical Education Program"
  label var c6_swalliedhed "c6 - salaries expense - Allied Health Education Program"
  label var c6_swcentradm "c6 - salaries expense - Central Supply-Administratioon"
  label var c6_swpharmadm "c6 - salaries expense - Pharmacy-Administration"
  label var c6_swgenrlacc "c6 - salaries expense - General Accounting"
  label var c6_swpatntacc "c6 - salaries expense - Patient Accounting / Admitting"
  label var c6_swhosptadm "c6 - salaries expense - Hospital Administration"
  label var c6_swdataproc "c6 - salaries expense - Data Processing Services"
  label var c6_swpurchsto "c6 - salaries expense - Purchasing / Storage"
  label var c6_swmdrecord "c6 - salaries expense - Medical Records Services"
  label var c6_swmedstadm "c6 - salaries expense - Medical Staff Administration"
  label var c6_swmedstaff "c6 - salaries expense - Medical Staff Services"
  label var c6_swmedcarer "c6 - salaries expense - Medical Care Review"
  label var c6_swnursgadm "c6 - salaries expense - Nursing Administration"
  label var c6_swfundrais "c6 - salaries expense - Fund Raising Expense"
  label var c6_swemplben "c6 - salaries expense - Employee Benefits / Nonpayroll"
  label var c6_swinsumalp "c6 - salaries expense - Insurance-Malpractice"
  label var c6_swinsother "c6 - salaries expense - Insurance-Other"


  label var c6_othresearexp "c6 - other expense - Research Expense"
  label var c6_othnurgsed "c6 - other expense - Nursing Education"
  label var c6_othapstgraded "c6 - other expense - Approved Graduate Medical Education Program"
  label var c6_othnpstgraded "c6 - other expense - Nonapproved Graduate Medical Education Program"
  label var c6_othalliedhed "c6 - other expense - Allied Health Education Program"
  label var c6_othcentradm "c6 - other expense - Central Supply-Administratioon"
  label var c6_othpharmadm "c6 - other expense - Pharmacy-Administration"
  label var c6_othgenrlacc "c6 - other expense - General Accounting"
  label var c6_othpatntacc "c6 - other expense - Patient Accounting / Admitting"
  label var c6_othhosptadm "c6 - other expense - Hospital Administration"
  label var c6_othdataproc "c6 - other expense - Data Processing Services"
  label var c6_othpurchsto "c6 - other expense - Purchasing / Storage"
  label var c6_othmdrecord "c6 - other expense - Medical Records Services"
  label var c6_othmedstadm "c6 - other expense - Medical Staff Administration"
  label var c6_othmedstaff "c6 - other expense - Medical Staff Services"
  label var c6_othmedcarer "c6 - other expense - Medical Care Review"
  label var c6_othnursgadm "c6 - other expense - Nursing Administration"
  label var c6_othfundrais "c6 - other expense - Fund Raising Expense"
  label var c6_othemplben "c6 - other expense - Employee Benefits / Nonpayroll"
  label var c6_othinsumalp "c6 - other expense - Insurance-Malpractice"
  label var c6_othinsother "c6 - other expense - Insurance-Other"

  label var c6_totresearexp "c6 - total expense - Research Expense"
  label var c6_totnurgsed "c6 - total expense - Nursing Education"
  label var c6_totapstgraded "c6 - total expense - Approved Graduate Medical Education Program"
  label var c6_totnpstgraded "c6 - total expense - Nonapproved Graduate Medical Education Program"
  label var c6_totalliedhed "c6 - total expense - Allied Health Education Program"
  label var c6_totcentradm "c6 - total expense - Central Supply-Administratioon"
  label var c6_totpharmadm "c6 - total expense - Pharmacy-Administration"
  label var c6_totgenrlacc "c6 - total expense - General Accounting"
  label var c6_totpatntacc "c6 - total expense - Patient Accounting / Admitting"
  label var c6_tothosptadm "c6 - total expense - Hospital Administration"
  label var c6_totdataproc "c6 - total expense - Data Processing Services"
  label var c6_totpurchsto "c6 - total expense - Purchasing / Storage"
  label var c6_totmdrecord "c6 - total expense - Medical Records Services"
  label var c6_totmedstadm "c6 - total expense - Medical Staff Administration"
  label var c6_totmedstaff "c6 - total expense - Medical Staff Services"
  label var c6_totmedcarer "c6 - total expense - Medical Care Review"
  label var c6_totnursgadm "c6 - total expense - Nursing Administration"
  label var c6_totfundrais "c6 - total expense - Fund Raising Expense"
  label var c6_totemplben "c6 - total expense - Employee Benefits / Nonpayroll"
  label var c6_totinsumalp "c6 - total expense - Insurance-Malpractice"
  label var c6_totinsother "c6 - total expense - Insurance-Other"

  label var c6_fteresearexp "c6 - FTE - Research Expense"
  label var c6_ftenurgsed "c6 - FTE - Nursing Education"
  label var c6_fteapstgraded "c6 - FTE - Approved Graduate Medical Education Program"
  label var c6_ftenpstgraded "c6 - FTE - Nonapproved Graduate Medical Education Program"
  label var c6_ftealliedhed "c6 - FTE - Allied Health Education Program"
  label var c6_ftecentradm "c6 - FTE - Central Supply-Administratioon"
  label var c6_ftepharmadm "c6 - FTE - Pharmacy-Administration"
  label var c6_ftegenrlacc "c6 - FTE - General Accounting"
  label var c6_ftepatntacc "c6 - FTE - Patient Accounting / Admitting"
  label var c6_ftehosptadm "c6 - FTE - Hospital Administration"
  label var c6_ftedataproc "c6 - FTE - Data Processing Services"
  label var c6_ftepurchsto "c6 - FTE - Purchasing / Storage"
  label var c6_ftemdrecord "c6 - FTE - Medical Records Services"
  label var c6_ftemedstadm "c6 - FTE - Medical Staff Administration"
  label var c6_ftemedstaff "c6 - FTE - Medical Staff Services"
  label var c6_ftemedcarer "c6 - FTE - Medical Care Review"
  label var c6_ftenursgadm "c6 - FTE - Nursing Administration"
  label var c6_ftefundrais "c6 - FTE - Fund Raising Expense"
  label var c6_fteemplben "c6 - FTE - Employee Benefits / Nonpayroll"
  label var c6_fteinsumalp "c6 - FTE - Insurance-Malpractice"
  label var c6_fteinsother "c6 - FTE - Insurance-Other" 


* 7. Drop remaining variables
  drop SALARY_WAGE*
  drop OTHER_EXPENSE*
  drop TOTAL_EXPENSE*
  drop FTE*
  drop N
 
* 8. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check
 
* 9. Save
  save ${sheets}fl_`i'_C6.dta, replace
  clear
}
  

*===============================================================================
* 10. Extract C-7 info - STATEMENT OF PHYSICIAN'S SERVICES REVENUE AND EXPENSE
*===============================================================================

* There's no C-7 information for 2019 and 2020

forvalues i=2004(1)2018 {

* 1. Import C-7 sheet
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_C7") firstrow allstring  clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"

* 4. Drop duplicate hospital observations
  // Each hospital has multiple rows and each row is a different variable  
  foreach x of varlist REVENUE-EXPENSE {
  destring `x', force replace
  }
  collapse (sum) REVENUE-EXPENSE, by(FILE_NBR LINE_NUMBER)
  bysort FILE_NBR LINE_NUMBER: ge N=_N
  tabulate N
  bysort FILE_NBR LINE_NUMBER: drop if _n>1
  drop N  

* 5. Reshape Data
  // Reshape data such that each hospital has one row and multiple column variables
  drop if LINE_NUMBER== "03a"
  destring LINE_NUMBER, force replace 
  reshape wide REVENUE-EXPENSE, i(FILE_NBR) j(LINE_NUMBER)
  describe // Data Check
  summarize // Data Check 
  
* 6. Renaming & labeling variables 
  rename FILE_NBR faclnbr
  
  rename REVENUE1 c7_revmedacu  
  rename REVENUE2 c7_revpedacu  
  rename REVENUE3 c7_revpsyacu  
  rename REVENUE4 c7_revobsacu  
  rename REVENUE5 c7_revdefobs  
  rename REVENUE6 c7_revothacu  
  rename REVENUE7 c7_revmedicu  
  rename REVENUE8 c7_revcorcar  
  rename REVENUE9 c7_revpedicu  
  rename REVENUE10 c7_revneoicu  
  rename REVENUE11 c7_revburcar  
  rename REVENUE12 c7_revpsyicu  
  rename REVENUE13 c7_revothicu  
  rename REVENUE14 c7_revnewbrn  
  rename REVENUE15 c7_revsknurs  
  rename REVENUE16 c7_revpsylng  
  rename REVENUE17 c7_revinterm  
  rename REVENUE18 c7_revrescar  
  rename REVENUE19 c7_revothsub  
  rename REVENUE20 c7_revtotdly  
  rename REVENUE21 c7_revemerge  
  rename REVENUE22 c7_revclinic  
  rename REVENUE23 c7_revhomdia  
  rename REVENUE24 c7_revambsur  
  rename REVENUE25 c7_revambser  
  rename REVENUE26 c7_revothamb  
  rename REVENUE27 c7_revfreest  
  rename REVENUE28 c7_revhomhlt  
  rename REVENUE29 c7_revtotamb   
  rename REVENUE30 c7_revdelivr  
  rename REVENUE31 c7_revsurger  
  rename REVENUE32 c7_revrecovr  
  rename REVENUE33 c7_revanesth  
  rename REVENUE34 c7_revsupply  
  rename REVENUE35 c7_revdrugss  
  rename REVENUE36 c7_revlabser  
  rename REVENUE37 c7_revblocol  
  rename REVENUE38 c7_revblobnk  
  rename REVENUE39 c7_revelectr  
  rename REVENUE40 c7_revcardia  
  rename REVENUE41 c7_revradiol  
  rename REVENUE42 c7_revtomogr  
  rename REVENUE43 c7_revmagres  
  rename REVENUE44 c7_revtherap  
  rename REVENUE45 c7_revnuclea  
  rename REVENUE46 c7_revrespir  
  rename REVENUE47 c7_revphythe  
  rename REVENUE48 c7_revothreh  
  rename REVENUE49 c7_revrenald  
  rename REVENUE50 c7_revlithot  
  rename REVENUE51 c7_revorganb  
  rename REVENUE52 c7_revothanc  
  rename REVENUE53 c7_revtotanc  
  rename REVENUE54 c7_revtotals  

  // DAILY HOSPITAL SERVICES
  label var c7_revmedacu "Medical / Surgical Acute"
  label var c7_revpedacu "Pediatric Acute"
  label var c7_revpsyacu "Psychiatric Acute"
  label var c7_revobsacu "Obstetrics Acute"
  label var c7_revdefobs "Definitive Observation"
  label var c7_revothacu "Other Acute Care"
  label var c7_revmedicu "Medical / Surgical ICU"
  label var c7_revcorcar "Coronary Care Unit"
  label var c7_revpedicu "Pediatric ICU"
  label var c7_revneoicu "Neonatal ICU"
  label var c7_revburcar "Burn Care Unit"
  label var c7_revpsyicu "Psychiatric ICU"
  label var c7_revothicu "Other Intensive Care"
  label var c7_revnewbrn "Newborn Nursery"
  label var c7_revsknurs "Skilled Nursing Facility"
  label var c7_revpsylng "Psychiatric Long-Term Care"
  label var c7_revinterm "Intermediate Care"
  label var c7_revrescar "Residential Care"
  label var c7_revothsub "Other Subacute Care"
  label var c7_revtotdly "Total Daily Hospital Services (Lines 1 through 19)"
  // AMBULATORY SERVICES
  label var c7_revemerge "Emergency Services"
  label var c7_revclinic "Clinic Services"
  label var c7_revhomdia "Home Dialysis Program"
  label var c7_revambsur "Ambulatory Surgery Services"
  label var c7_revambser "Ambulance Services"
  label var c7_revothamb "Other Ambulatory Services"
  label var c7_revfreest "Free Standing Clinic"
  label var c7_revhomhlt "Home Health Services"
  label var c7_revtotamb "Total Ambulatory Services (Lines 21 through 28)"
  // ANCILLARY SERVICES
  label var c7_revdelivr "Labor and Delivery Services"
  label var c7_revsurger "Surgery Services"
  label var c7_revrecovr "Recovery Services"
  label var c7_revanesth "Anesthesiology"
  label var c7_revsupply "Medical Supplies Sold"
  label var c7_revdrugss "Drugs Sold"
  label var c7_revlabser "Laboratory Services"
  label var c7_revblocol "Blood / Plasma Collection"
  label var c7_revblobnk "Blood Bank - Processing & Storage"
  label var c7_revelectr "Electrocardiography (ECG)"
  label var c7_revcardia "Cardiac Catherterization"
  label var c7_revradiol "Radiology/ Diagnostic"
  label var c7_revtomogr "Computerized Tomography (CT)"
  label var c7_revmagres "Magnetic Resonance Imaging (MRI)"
  label var c7_revtherap "Radiology / Therapeutic"
  label var c7_revnuclea "Nuclear Medicine"
  label var c7_revrespir "Respiratory Therapy"
  label var c7_revphythe "Physical Therapy"
  label var c7_revothreh "Other Rehabilitative Services"
  label var c7_revrenald "Renal Dialysis"
  label var c7_revlithot "ESW Lithotripsy"
  label var c7_revorganb "Organ Acquisition & Banking"
  label var c7_revothanc "Other Ancillary Services"
  label var c7_revtotanc "Total Ancillary Services (Lines 30 through 52)"
  label var c7_revtotals "Total Patient Care Services (Lines 20, 29 & 53)"

  rename EXPENSE1 c7_expmedacu
  rename EXPENSE2 c7_exppedacu
  rename EXPENSE3 c7_exppsyacu
  rename EXPENSE4 c7_expobsacu
  rename EXPENSE5 c7_expdefobs
  rename EXPENSE6 c7_expothacu
  rename EXPENSE7 c7_expmedicu
  rename EXPENSE8 c7_expcorcar
  rename EXPENSE9 c7_exppedicu
  rename EXPENSE10 c7_expneoicu
  rename EXPENSE11 c7_expburcar
  rename EXPENSE12 c7_exppsyicu
  rename EXPENSE13 c7_expothicu
  rename EXPENSE14 c7_expnewbrn
  rename EXPENSE15 c7_expsknurs
  rename EXPENSE16 c7_exppsylng
  rename EXPENSE17 c7_expinterm
  rename EXPENSE18 c7_exprescar
  rename EXPENSE19 c7_expothsub
  rename EXPENSE20 c7_exptotdly
  rename EXPENSE21 c7_expemerge
  rename EXPENSE22 c7_expclinic
  rename EXPENSE23 c7_exphomdia
  rename EXPENSE24 c7_expambsur
  rename EXPENSE25 c7_expambser
  rename EXPENSE26 c7_expothamb
  rename EXPENSE27 c7_expfreest
  rename EXPENSE28 c7_exphomhlt
  rename EXPENSE29 c7_exptotamb
  rename EXPENSE30 c7_expdelivr
  rename EXPENSE31 c7_expsurger
  rename EXPENSE32 c7_exprecovr
  rename EXPENSE33 c7_expanesth
  rename EXPENSE34 c7_expsupply
  rename EXPENSE35 c7_expdrugss
  rename EXPENSE36 c7_explabser
  rename EXPENSE37 c7_expblocol
  rename EXPENSE38 c7_expblobnk
  rename EXPENSE39 c7_expelectr
  rename EXPENSE40 c7_expcardia
  rename EXPENSE41 c7_expradiol
  rename EXPENSE42 c7_exptomogr
  rename EXPENSE43 c7_expmagres
  rename EXPENSE44 c7_exptherap
  rename EXPENSE45 c7_expnuclea
  rename EXPENSE46 c7_exprespir
  rename EXPENSE47 c7_expphythe
  rename EXPENSE48 c7_expothreh
  rename EXPENSE49 c7_exprenald
  rename EXPENSE50 c7_explithot
  rename EXPENSE51 c7_exporganb
  rename EXPENSE52 c7_expothanc
  rename EXPENSE53 c7_exptotanc
  rename EXPENSE54 c7_exptotals

  // DAILY HOSPITAL SERVICES
  label var c7_expmedacu "Medical / Surgical Acute"
  label var c7_exppedacu "Pediatric Acute"
  label var c7_exppsyacu "Psychiatric Acute"
  label var c7_expobsacu "Obstetrics Acute"
  label var c7_expdefobs "Definitive Observation"
  label var c7_expothacu "Other Acute Care"
  label var c7_expmedicu "Medical / Surgical ICU"
  label var c7_expcorcar "Coronary Care Unit"
  label var c7_exppedicu "Pediatric ICU"
  label var c7_expneoicu "Neonatal ICU"
  label var c7_expburcar "Burn Care Unit"
  label var c7_exppsyicu "Psychiatric ICU"
  label var c7_expothicu "Other Intensive Care"
  label var c7_expnewbrn "Newborn Nursery"
  label var c7_expsknurs "Skilled Nursing Facility"
  label var c7_exppsylng "Psychiatric Long-Term Care"
  label var c7_expinterm "Intermediate Care"
  label var c7_exprescar "Residential Care"
  label var c7_expothsub "Other Subacute Care"
  label var c7_exptotdly "Total Daily Hospital Services (Lines 1 through 19)"
  // AMBULATORY SERVICES
  label var c7_expemerge "Emergency Services"
  label var c7_expclinic "Clinic Services"
  label var c7_exphomdia "Home Dialysis Program"
  label var c7_expambsur "Ambulatory Surgery Services"
  label var c7_expambser "Ambulance Services"
  label var c7_expothamb "Other Ambulatory Services"
  label var c7_expfreest "Free Standing Clinic"
  label var c7_exphomhlt "Home Health Services"
  label var c7_exptotamb "Total Ambulatory Services (Lines 21 through 28)"
  // ANCILLARY SERVICES
  label var c7_expdelivr "Labor and Delivery Services"
  label var c7_expsurger "Surgery Services"
  label var c7_exprecovr "Recovery Services"
  label var c7_expanesth "Anesthesiology"
  label var c7_expsupply "Medical Supplies Sold"
  label var c7_expdrugss "Drugs Sold"
  label var c7_explabser "Laboratory Services"
  label var c7_expblocol "Blood / Plasma Collection"
  label var c7_expblobnk "Blood Bank - Processing & Storage"
  label var c7_expelectr "Electrocardiography (ECG)"
  label var c7_expcardia "Cardiac Catherterization"
  label var c7_expradiol "Radiology/ Diagnostic"
  label var c7_exptomogr "Computerized Tomography (CT)"
  label var c7_expmagres "Magnetic Resonance Imaging (MRI)"
  label var c7_exptherap "Radiology / Therapeutic"
  label var c7_expnuclea "Nuclear Medicine"
  label var c7_exprespir "Respiratory Therapy"
  label var c7_expphythe "Physical Therapy"
  label var c7_expothreh "Other Rehabilitative Services"
  label var c7_exprenald "Renal Dialysis"
  label var c7_explithot "ESW Lithotripsy"
  label var c7_exporganb "Organ Acquisition & Banking"
  label var c7_expothanc "Other Ancillary Services"
  label var c7_exptotanc "Total Ancillary Services (Lines 30 through 52)"
  label var c7_exptotals "Total Patient Care Services (Lines 20, 29 & 53)"

* 7. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check
  
* 8. Save
  save ${sheets}fl_`i'_C7.dta, replace
  clear
}
  


*===============================================================================
* 11. Extract E-a1 info - COST ALLOCATION/STATISTICAL BASIS
*===============================================================================

* There's no E-a1 information for 2019 and 2020
  
forvalues i=2004(1)2018 {

* 1. Import E1-a sheet 
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_E1A") firstrow allstring  clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"

* 4. Drop duplicate hospital observations
  // Each hospital has multiple rows and each row is a different variable  
  foreach x of varlist SQUARE_FEET-NUMBER_HOUSED {
  destring `x', force replace
  }
  collapse (sum) SQUARE_FEET-NUMBER_HOUSED, by(FILE_NBR LINE_NUMBER)
  bysort FILE_NBR LINE_NUMBER: ge N=_N
  tabulate N
  bysort FILE_NBR LINE_NUMBER: drop if _n>1
  drop N
   
* 5. Reshape Data
  // Reshape data such that each hospital has one row and multiple column variables
  replace LINE_NUMBER= "99" if LINE_NUMBER== "24a" // otherwise cannot destring
  drop if LINE_NUMBER== "38a" 
  destring LINE_NUMBER, force replace 
  reshape wide SQUARE_FEET-NUMBER_HOUSED, i(FILE_NBR) j(LINE_NUMBER)
  describe // Data Check
  summarize // Data Check 

* 6. Renaming & labeling variables 
  rename FILE_NBR faclnbr
  
  rename SQUARE_FEET1 e1a_sqtotstats
  rename SQUARE_FEET3 e1a_sqfemplben
  rename SQUARE_FEET5 e1a_sqfpatntacc
  rename SQUARE_FEET6 e1a_sqfothgadm
  rename SQUARE_FEET13 e1a_sqfnursadm
  rename SQUARE_FEET14 e1a_sqfcentrsr
  rename SQUARE_FEET15 e1a_sqfpharm
  rename SQUARE_FEET16 e1a_sqfmedreco
  rename SQUARE_FEET17 e1a_sqfsocserv
  rename SQUARE_FEET18 e1a_sqfnursged
  rename SQUARE_FEET19 e1a_sqfapgradme
  rename SQUARE_FEET23 e1a_sqfraddiag
  rename SQUARE_FEET24 e1a_sqfcomptom
  rename SQUARE_FEET99 e1a_sqfmrimag
  rename SQUARE_FEET25 e1a_sqfradther
  rename SQUARE_FEET26 e1a_sqfnuclmed
  rename SQUARE_FEET27 e1a_sqflabserv
  rename SQUARE_FEET28 e1a_sqfanesth
  rename SQUARE_FEET29 e1a_sqfelectr
  rename SQUARE_FEET30 e1a_sqfcardcat
  rename SQUARE_FEET31 e1a_sqfmedsold
  rename SQUARE_FEET32 e1a_sqfdrgsold
  rename SQUARE_FEET55 e1a_sqfemergse
  rename SQUARE_FEET56 e1a_sqfclinser
  rename SQUARE_FEET59 e1a_sqffreestc
  rename SQUARE_FEET63 e1a_sqfnpgradme
  rename SQUARE_FEET64 e1a_sqfresearch
  
  rename COST_OF_SUPPLIES1 e1a_cstotstats
  rename COST_OF_SUPPLIES3 e1a_csemplben
  rename COST_OF_SUPPLIES5 e1a_cspatntacc
  rename COST_OF_SUPPLIES6 e1a_csothgadm
  rename COST_OF_SUPPLIES13 e1a_csnursadm
  rename COST_OF_SUPPLIES14 e1a_cscentrsr
  rename COST_OF_SUPPLIES15 e1a_cspharm
  rename COST_OF_SUPPLIES16 e1a_csmedreco
  rename COST_OF_SUPPLIES17 e1a_cssocserv
  rename COST_OF_SUPPLIES18 e1a_csnursged
  rename COST_OF_SUPPLIES19 e1a_csapgradme
  rename COST_OF_SUPPLIES23 e1a_csraddiag
  rename COST_OF_SUPPLIES24 e1a_cscomptom
  rename COST_OF_SUPPLIES99 e1a_csmrimag
  rename COST_OF_SUPPLIES25 e1a_csradther
  rename COST_OF_SUPPLIES26 e1a_csnuclmed
  rename COST_OF_SUPPLIES27 e1a_cslabserv
  rename COST_OF_SUPPLIES28 e1a_csanesth
  rename COST_OF_SUPPLIES29 e1a_cselectr
  rename COST_OF_SUPPLIES30 e1a_cscardcat
  rename COST_OF_SUPPLIES31 e1a_csmedsold
  rename COST_OF_SUPPLIES32 e1a_csdrgsold
  rename COST_OF_SUPPLIES55 e1a_csemergse
  rename COST_OF_SUPPLIES56 e1a_csclinser
  rename COST_OF_SUPPLIES59 e1a_csfreestc
  rename COST_OF_SUPPLIES63 e1a_csnpgradme
  rename COST_OF_SUPPLIES64 e1a_csresearch
  
  rename POUNDS_OF_LAUNDRY1 e1a_pltotstats
  rename POUNDS_OF_LAUNDRY3 e1a_plemplben
  rename POUNDS_OF_LAUNDRY5 e1a_plpatntacc
  rename POUNDS_OF_LAUNDRY6 e1a_plothgadm
  rename POUNDS_OF_LAUNDRY13 e1a_plnursadm
  rename POUNDS_OF_LAUNDRY14 e1a_plcentrsr
  rename POUNDS_OF_LAUNDRY15 e1a_plpharm
  rename POUNDS_OF_LAUNDRY16 e1a_plmedreco
  rename POUNDS_OF_LAUNDRY17 e1a_plsocserv
  rename POUNDS_OF_LAUNDRY18 e1a_plnursged
  rename POUNDS_OF_LAUNDRY19 e1a_plapgradme
  rename POUNDS_OF_LAUNDRY23 e1a_plraddiag
  rename POUNDS_OF_LAUNDRY24 e1a_plcomptom
  rename POUNDS_OF_LAUNDRY99 e1a_plmrimag
  rename POUNDS_OF_LAUNDRY25 e1a_plradther
  rename POUNDS_OF_LAUNDRY26 e1a_plnuclmed
  rename POUNDS_OF_LAUNDRY27 e1a_pllabserv
  rename POUNDS_OF_LAUNDRY28 e1a_planesth
  rename POUNDS_OF_LAUNDRY29 e1a_plelectr
  rename POUNDS_OF_LAUNDRY30 e1a_plcardcat
  rename POUNDS_OF_LAUNDRY31 e1a_plmedsold
  rename POUNDS_OF_LAUNDRY32 e1a_pldrgsold
  rename POUNDS_OF_LAUNDRY55 e1a_plemergse
  rename POUNDS_OF_LAUNDRY56 e1a_plclinser
  rename POUNDS_OF_LAUNDRY59 e1a_plfreestc
  rename POUNDS_OF_LAUNDRY63 e1a_plnpgradme
  rename POUNDS_OF_LAUNDRY64 e1a_plresearch
  
  rename NUMBER_HOUSED1 e1a_nhtotstats
  rename NUMBER_HOUSED3 e1a_nhemplben
  rename NUMBER_HOUSED5 e1a_nhpatntacc
  rename NUMBER_HOUSED6 e1a_nhothgadm
  rename NUMBER_HOUSED13 e1a_nhnursadm
  rename NUMBER_HOUSED14 e1a_nhcentrsr
  rename NUMBER_HOUSED15 e1a_nhpharm
  rename NUMBER_HOUSED16 e1a_nhmedreco
  rename NUMBER_HOUSED17 e1a_nhsocserv
  rename NUMBER_HOUSED18 e1a_nhnursged
  rename NUMBER_HOUSED19 e1a_nhapgradme
  rename NUMBER_HOUSED23 e1a_nhraddiag
  rename NUMBER_HOUSED24 e1a_nhcomptom
  rename NUMBER_HOUSED99 e1a_nhmrimag
  rename NUMBER_HOUSED25 e1a_nhradther
  rename NUMBER_HOUSED26 e1a_nhnuclmed
  rename NUMBER_HOUSED27 e1a_nhlabserv
  rename NUMBER_HOUSED28 e1a_nhanesth
  rename NUMBER_HOUSED29 e1a_nhelectr
  rename NUMBER_HOUSED30 e1a_nhcardcat
  rename NUMBER_HOUSED31 e1a_nhmedsold
  rename NUMBER_HOUSED32 e1a_nhdrgsold
  rename NUMBER_HOUSED55 e1a_nhemergse
  rename NUMBER_HOUSED56 e1a_nhclinser
  rename NUMBER_HOUSED59 e1a_nhfreestc
  rename NUMBER_HOUSED63 e1a_nhnpgradme
  rename NUMBER_HOUSED64 e1a_nhresearch


  label var e1a_sqtotstats "e1a - square feet - Total Statistics (Lines 2 through 64)"
  label var e1a_sqfemplben  "e1a - square feet - Employee Benefits / Non-payroll"
  label var e1a_sqfpatntacc "e1a - square feet - Patient Accounting / Admitting"
  label var e1a_sqfothgadm "e1a - square feet - Other General & Administrative"
  label var e1a_sqfnursadm "e1a - square feet - Nursing Administration"
  label var e1a_sqfcentrsr "e1a - square feet - Central Supply & Services (CSR)"
  label var e1a_sqfpharm "e1a - square feet - Pharmacy"
  label var e1a_sqfmedreco "e1a - square feet - Medical Records"
  label var e1a_sqfsocserv "e1a - square feet - Social Services"
  label var e1a_sqfnursged "e1a - square feet - Nursing Education"
  label var e1a_sqfapgradme "e1a - square feet - Approved Graduate Medical Education"
  label var e1a_sqfraddiag "e1a - square feet - Radiology-Diagnostic"
  label var e1a_sqfcomptom "e1a - square feet - Computerized Tomography"
  label var e1a_sqfmrimag "e1a - square feet - Magnetic Resonance Imaging (MRI)"
  label var e1a_sqfradther "e1a - square feet - Radiology-Therapeutic"
  label var e1a_sqfnuclmed "e1a - square feet - Nuclear Medicine"
  label var e1a_sqflabserv "e1a - square feet - Laboratory Services"
  label var e1a_sqfanesth "e1a - square feet - Anesthesiology"
  label var e1a_sqfelectr "e1a - square feet - Electrocardiography (ECG)"
  label var e1a_sqfcardcat "e1a - square feet - Cardiac Catheterization"
  label var e1a_sqfmedsold "e1a - square feet - Medical Supplies Sold"
  label var e1a_sqfdrgsold "e1a - square feet - Drugs Sold"
  label var e1a_sqfemergse "e1a - square feet - Emergency Services"
  label var e1a_sqfclinser "e1a - square feet - Clinic Services"
  label var e1a_sqffreestc "e1a - square feet - Free Standing Clinic"
  label var e1a_sqfnpgradme "e1a - square feet - Nonapproved Graduate Medical Education"
  label var e1a_sqfresearch "e1a - square feet - Research"
  
  label var e1a_cstotstats "e1a - cost of supplies - Total Statistics (Lines 2 through 64)"
  label var e1a_csemplben  "e1a - cost of supplies - Employee Benefits / Non-payroll"
  label var e1a_cspatntacc "e1a - cost of supplies - Patient Accounting / Admitting"
  label var e1a_csothgadm "e1a - cost of supplies - Other General & Administrative"
  label var e1a_csnursadm "e1a - cost of supplies - Nursing Administration"
  label var e1a_cscentrsr "e1a - cost of supplies - Central Supply & Services (CSR)"
  label var e1a_cspharm "e1a - cost of supplies - Pharmacy"
  label var e1a_csmedreco "e1a - cost of supplies - Medical Records"
  label var e1a_cssocserv "e1a - cost of supplies - Social Services"
  label var e1a_csnursged "e1a - cost of supplies - Nursing Education"
  label var e1a_csapgradme "e1a - cost of supplies - Approved Graduate Medical Education"
  label var e1a_csraddiag "e1a - cost of supplies - Radiology-Diagnostic"
  label var e1a_cscomptom "e1a - cost of supplies - Computerized Tomography"
  label var e1a_csmrimag "e1a - cost of supplies - Magnetic Resonance Imaging (MRI)"
  label var e1a_csradther "e1a - cost of supplies - Radiology-Therapeutic"
  label var e1a_csnuclmed "e1a - cost of supplies - Nuclear Medicine"
  label var e1a_cslabserv "e1a - cost of supplies - Laboratory Services"
  label var e1a_csanesth "e1a - cost of supplies - Anesthesiology"
  label var e1a_cselectr "e1a - cost of supplies - Electrocardiography (ECG)"
  label var e1a_cscardcat "e1a - cost of supplies - Cardiac Catheterization"
  label var e1a_csmedsold "e1a - cost of supplies - Medical Supplies Sold"
  label var e1a_csdrgsold "e1a - cost of supplies - Drugs Sold"
  label var e1a_csemergse "e1a - cost of supplies - Emergency Services"
  label var e1a_csclinser "e1a - cost of supplies - Clinic Services"
  label var e1a_csfreestc "e1a - cost of supplies - Free Standing Clinic"
  label var e1a_csnpgradme "e1a - cost of supplies - Nonapproved Graduate Medical Education"
  label var e1a_csresearch "e1a - cost of supplies - Research"

  label var e1a_pltotstats "e1a - pounds of laundry - Total Statistics (Lines 2 through 64)"
  label var e1a_plemplben  "e1a - pounds of laundry - Employee Benefits / Non-payroll"
  label var e1a_plpatntacc "e1a - pounds of laundry - Patient Accounting / Admitting"
  label var e1a_plothgadm "e1a - pounds of laundry - Other General & Administrative"
  label var e1a_plnursadm "e1a - pounds of laundry - Nursing Administration"
  label var e1a_plcentrsr "e1a - pounds of laundry - Central Supply & Services (CSR)"
  label var e1a_plpharm "e1a - pounds of laundry - Pharmacy"
  label var e1a_plmedreco "e1a - pounds of laundry - Medical Records"
  label var e1a_plsocserv "e1a - pounds of laundry - Social Services"
  label var e1a_plnursged "e1a - pounds of laundry - Nursing Education"
  label var e1a_plapgradme "e1a - pounds of laundry - Approved Graduate Medical Education"
  label var e1a_plraddiag "e1a - pounds of laundry - Radiology-Diagnostic"
  label var e1a_plcomptom "e1a - pounds of laundry - Computerized Tomography"
  label var e1a_plmrimag "e1a - pounds of laundry - Magnetic Resonance Imaging (MRI)"
  label var e1a_plradther "e1a - pounds of laundry - Radiology-Therapeutic"
  label var e1a_plnuclmed "e1a - pounds of laundry - Nuclear Medicine"
  label var e1a_pllabserv "e1a - pounds of laundry - Laboratory Services"
  label var e1a_planesth "e1a - pounds of laundry - Anesthesiology"
  label var e1a_plelectr "e1a - pounds of laundry - Electrocardiography (ECG)"
  label var e1a_plcardcat "e1a - pounds of laundry - Cardiac Catheterization"
  label var e1a_plmedsold "e1a - pounds of laundry - Medical Supplies Sold"
  label var e1a_pldrgsold "e1a - pounds of laundry - Drugs Sold"
  label var e1a_plemergse "e1a - pounds of laundry - Emergency Services"
  label var e1a_plclinser "e1a - pounds of laundry - Clinic Services"
  label var e1a_plfreestc "e1a - pounds of laundry - Free Standing Clinic"
  label var e1a_plnpgradme "e1a - pounds of laundry - Nonapproved Graduate Medical Education"
  label var e1a_plresearch "e1a - pounds of laundry - Research"

  label var e1a_nhtotstats "e1a - number housed - Total Statistics (Lines 2 through 64)"
  label var e1a_nhemplben  "e1a - number housed - Employee Benefits / Non-payroll"
  label var e1a_nhpatntacc "e1a - number housed - Patient Accounting / Admitting"
  label var e1a_nhothgadm "e1a - number housed - Other General & Administrative"
  label var e1a_nhnursadm "e1a - number housed - Nursing Administration"
  label var e1a_nhcentrsr "e1a - number housed - Central Supply & Services (CSR)"
  label var e1a_nhpharm "e1a - number housed - Pharmacy"
  label var e1a_nhmedreco "e1a - number housed - Medical Records"
  label var e1a_nhsocserv "e1a - number housed - Social Services"
  label var e1a_nhnursged "e1a - number housed - Nursing Education"
  label var e1a_nhapgradme "e1a - number housed - Approved Graduate Medical Education"
  label var e1a_nhraddiag "e1a - number housed - Radiology-Diagnostic"
  label var e1a_nhcomptom "e1a - number housed - Computerized Tomography"
  label var e1a_nhmrimag "e1a - number housed - Magnetic Resonance Imaging (MRI)"
  label var e1a_nhradther "e1a - number housed - Radiology-Therapeutic"
  label var e1a_nhnuclmed "e1a - number housed - Nuclear Medicine"
  label var e1a_nhlabserv "e1a - number housed - Laboratory Services"
  label var e1a_nhanesth "e1a - number housed - Anesthesiology"
  label var e1a_nhelectr "e1a - number housed - Electrocardiography (ECG)"
  label var e1a_nhcardcat "e1a - number housed - Cardiac Catheterization"
  label var e1a_nhmedsold "e1a - number housed - Medical Supplies Sold"
  label var e1a_nhdrgsold "e1a - number housed - Drugs Sold"
  label var e1a_nhemergse "e1a - number housed - Emergency Services"
  label var e1a_nhclinser "e1a - number housed - Clinic Services"
  label var e1a_nhfreestc "e1a - number housed - Free Standing Clinic"
  label var e1a_nhnpgradme "e1a - number housed - Nonapproved Graduate Medical Education"
  label var e1a_nhresearch "e1a - number housed - Research"

* 7. Drop remaining variables
  drop SQUARE_FEET*
  drop COST_OF_SUPPLIES*
  drop POUNDS_OF_LAUNDRY*
  drop NUMBER_HOUSED*

* 8. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check

* 9. Save
  save ${sheets}fl_`i'_E1a.dta, replace
  clear
}
  

  
*===============================================================================
* 12. Extract E-ab info - COST ALLOCATION/STATISTICAL BASIS						
*===============================================================================

* There's no E-a1 information for 2019 and 2020  

forvalues i=2004(1)2018 {

* 1. Import E1-b sheet 
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_E1B") firstrow allstring  clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"

* 4. Drop duplicate hospital observations
  // Each hospital has multiple rows and each row is a different variable  
  foreach x of varlist NURSING_FTE-ASSIGNED_TIME {
  destring `x', force replace
  }
  collapse (sum) NURSING_FTE-ASSIGNED_TIME, by(FILE_NBR LINE_NUMBER)
  bysort FILE_NBR LINE_NUMBER: ge N=_N
  tabulate N
  bysort FILE_NBR LINE_NUMBER: drop if _n>1
  drop N

* 5. Reshape Data
  // Reshape data such that each hospital has one row and multiple column variables
  replace LINE_NUMBER= "99" if LINE_NUMBER== "24a" // otherwise cannot destring
  drop if LINE_NUMBER== "38a" 
  destring LINE_NUMBER, force replace 
  reshape wide NURSING_FTE-ASSIGNED_TIME, i(FILE_NBR) j(LINE_NUMBER)
  describe // Data Check
  summarize // Data Check 

* 6. Renaming & labeling variables 
  rename FILE_NBR faclnbr
 
  rename NURSING_FTE1 e1b_nftetotstats
  rename NURSING_FTE3 e1b_nftefemplben
  rename NURSING_FTE5 e1b_nftefpatntacc
  rename NURSING_FTE6 e1b_nftefothgadm
  rename NURSING_FTE13 e1b_nftefnursadm
  rename NURSING_FTE14 e1b_nftefcentrsr
  rename NURSING_FTE15 e1b_nftefpharm
  rename NURSING_FTE16 e1b_nftefmedreco
  rename NURSING_FTE17 e1b_nftefsocserv
  rename NURSING_FTE18 e1b_nftefnursged
  rename NURSING_FTE19 e1b_nftefapgradme
  rename NURSING_FTE23 e1b_nftefraddiag
  rename NURSING_FTE24 e1b_nftefcomptom
  rename NURSING_FTE99 e1b_nftefmrimag
  rename NURSING_FTE25 e1b_nftefradther
  rename NURSING_FTE26 e1b_nftefnuclmed
  rename NURSING_FTE27 e1b_nfteflabserv
  rename NURSING_FTE28 e1b_nftefanesth
  rename NURSING_FTE29 e1b_nftefelectr
  rename NURSING_FTE30 e1b_nftefcardcat
  rename NURSING_FTE31 e1b_nftefmedsold
  rename NURSING_FTE32 e1b_nftefdrgsold
  rename NURSING_FTE55 e1b_nftefemergse
  rename NURSING_FTE56 e1b_nftefclinser
  rename NURSING_FTE59 e1b_nfteffreestc
  rename NURSING_FTE63 e1b_nftefnpgradme
  rename NURSING_FTE64 e1b_nftefresearch
 
  rename CSR_CSTD_REQ1 e1b_csrtotstats
  rename CSR_CSTD_REQ3 e1b_csremplben
  rename CSR_CSTD_REQ5 e1b_csrpatntacc
  rename CSR_CSTD_REQ6 e1b_csrothgadm
  rename CSR_CSTD_REQ13 e1b_csrnursadm
  rename CSR_CSTD_REQ14 e1b_csrcentrsr
  rename CSR_CSTD_REQ15 e1b_csrpharm
  rename CSR_CSTD_REQ16 e1b_csrmedreco
  rename CSR_CSTD_REQ17 e1b_csrsocserv
  rename CSR_CSTD_REQ18 e1b_csrnursged
  rename CSR_CSTD_REQ19 e1b_csrapgradme
  rename CSR_CSTD_REQ23 e1b_csrraddiag
  rename CSR_CSTD_REQ24 e1b_csrcomptom
  rename CSR_CSTD_REQ99 e1b_csrmrimag
  rename CSR_CSTD_REQ25 e1b_csrradther
  rename CSR_CSTD_REQ26 e1b_csrnuclmed
  rename CSR_CSTD_REQ27 e1b_csrlabserv
  rename CSR_CSTD_REQ28 e1b_csranesth
  rename CSR_CSTD_REQ29 e1b_csrelectr
  rename CSR_CSTD_REQ30 e1b_csrcardcat
  rename CSR_CSTD_REQ31 e1b_csrmedsold
  rename CSR_CSTD_REQ32 e1b_csrdrgsold
  rename CSR_CSTD_REQ55 e1b_csremergse
  rename CSR_CSTD_REQ56 e1b_csrclinser
  rename CSR_CSTD_REQ59 e1b_csrfreestc
  rename CSR_CSTD_REQ63 e1b_csrnpgradme
  rename CSR_CSTD_REQ64 e1b_csrresearch
 
  rename PHARMACY_CSTD_REQ1 e1b_phartotstats
  rename PHARMACY_CSTD_REQ3 e1b_pharemplben
  rename PHARMACY_CSTD_REQ5 e1b_pharpatntacc
  rename PHARMACY_CSTD_REQ6 e1b_pharothgadm
  rename PHARMACY_CSTD_REQ13 e1b_pharnursadm
  rename PHARMACY_CSTD_REQ14 e1b_pharcentrsr
  rename PHARMACY_CSTD_REQ15 e1b_pharpharm
  rename PHARMACY_CSTD_REQ16 e1b_pharmedreco
  rename PHARMACY_CSTD_REQ17 e1b_pharsocserv
  rename PHARMACY_CSTD_REQ18 e1b_pharnursged
  rename PHARMACY_CSTD_REQ19 e1b_pharapgradme
  rename PHARMACY_CSTD_REQ23 e1b_pharraddiag
  rename PHARMACY_CSTD_REQ24 e1b_pharcomptom
  rename PHARMACY_CSTD_REQ99 e1b_pharmrimag
  rename PHARMACY_CSTD_REQ25 e1b_pharradther
  rename PHARMACY_CSTD_REQ26 e1b_pharnuclmed
  rename PHARMACY_CSTD_REQ27 e1b_pharlabserv
  rename PHARMACY_CSTD_REQ28 e1b_pharanesth
  rename PHARMACY_CSTD_REQ29 e1b_pharelectr
  rename PHARMACY_CSTD_REQ30 e1b_pharcardcat
  rename PHARMACY_CSTD_REQ31 e1b_pharmedsold
  rename PHARMACY_CSTD_REQ32 e1b_phardrgsold
  rename PHARMACY_CSTD_REQ55 e1b_pharemergse
  rename PHARMACY_CSTD_REQ56 e1b_pharclinser
  rename PHARMACY_CSTD_REQ59 e1b_pharfreestc
  rename PHARMACY_CSTD_REQ63 e1b_pharnpgradme
  rename PHARMACY_CSTD_REQ64 e1b_pharresearch
 
  rename ASSIGNED_TIME1 e1b_asttotstats
  rename ASSIGNED_TIME3 e1b_astemplben
  rename ASSIGNED_TIME5 e1b_astpatntacc
  rename ASSIGNED_TIME6 e1b_astothgadm
  rename ASSIGNED_TIME13 e1b_astnursadm
  rename ASSIGNED_TIME14 e1b_astcentrsr
  rename ASSIGNED_TIME15 e1b_astpharm
  rename ASSIGNED_TIME16 e1b_astmedreco
  rename ASSIGNED_TIME17 e1b_astsocserv
  rename ASSIGNED_TIME18 e1b_astnursged
  rename ASSIGNED_TIME19 e1b_astapgradme
  rename ASSIGNED_TIME23 e1b_astraddiag
  rename ASSIGNED_TIME24 e1b_astcomptom
  rename ASSIGNED_TIME99 e1b_astmrimag
  rename ASSIGNED_TIME25 e1b_astradther
  rename ASSIGNED_TIME26 e1b_astnuclmed
  rename ASSIGNED_TIME27 e1b_astlabserv
  rename ASSIGNED_TIME28 e1b_astanesth
  rename ASSIGNED_TIME29 e1b_astelectr
  rename ASSIGNED_TIME30 e1b_astcardcat
  rename ASSIGNED_TIME31 e1b_astmedsold
  rename ASSIGNED_TIME32 e1b_astdrgsold
  rename ASSIGNED_TIME55 e1b_astemergse
  rename ASSIGNED_TIME56 e1b_astclinser
  rename ASSIGNED_TIME59 e1b_astfreestc
  rename ASSIGNED_TIME63 e1b_astnpgradme
  rename ASSIGNED_TIME64 e1b_astresearch


  label var e1b_nftetotstats "e1b - nursing FTE's - Total Statistics (Lines 2 through 64)"
  label var e1b_nftefemplben  "e1b - nursing FTE's - Employee Benefits / Non-payroll"
  label var e1b_nftefpatntacc "e1b - nursing FTE's - Patient Accounting / Admitting"
  label var e1b_nftefothgadm "e1b - nursing FTE's - Other General & Administrative"
  label var e1b_nftefnursadm "e1b - nursing FTE's - Nursing Administration"
  label var e1b_nftefcentrsr "e1b - nursing FTE's - Central Supply & Services (CSR)"
  label var e1b_nftefpharm "e1b - nursing FTE's - Pharmacy"
  label var e1b_nftefmedreco "e1b - nursing FTE's - Medical Records"
  label var e1b_nftefsocserv "e1b - nursing FTE's - Social Services"
  label var e1b_nftefnursged "e1b - nursing FTE's - Nursing Education"
  label var e1b_nftefapgradme "e1b - nursing FTE's - Approved Graduate Medical Education"
  label var e1b_nftefraddiag "e1b - nursing FTE's - Radiology-Diagnostic"
  label var e1b_nftefcomptom "e1b - nursing FTE's - Computerized Tomography"
  label var e1b_nftefmrimag "e1b - nursing FTE's - Magnetic Resonance Imaging (MRI)"
  label var e1b_nftefradther "e1b - nursing FTE's - Radiology-Therapeutic"
  label var e1b_nftefnuclmed "e1b - nursing FTE's - Nuclear Medicine"
  label var e1b_nfteflabserv "e1b - nursing FTE's - Laboratory Services"
  label var e1b_nftefanesth "e1b - nursing FTE's - Anesthesiology"
  label var e1b_nftefelectr "e1b - nursing FTE's - Electrocardiography (ECG)"
  label var e1b_nftefcardcat "e1b - nursing FTE's - Cardiac Catheterization"
  label var e1b_nftefmedsold "e1b - nursing FTE's - Medical Supplies Sold"
  label var e1b_nftefdrgsold "e1b - nursing FTE's - Drugs Sold"
  label var e1b_nftefemergse "e1b - nursing FTE's - Emergency Services"
  label var e1b_nftefclinser "e1b - nursing FTE's - Clinic Services"
  label var e1b_nfteffreestc "e1b - nursing FTE's - Free Standing Clinic"
  label var e1b_nftefnpgradme "e1b - nursing FTE's - Nonapproved Graduate Medical Education"
  label var e1b_nftefresearch "e1b - nursing FTE's - Research"
 
  label var e1b_csrtotstats "e1b - CSR CSTD REQ - Total Statistics (Lines 2 through 64)"
  label var e1b_csremplben  "e1b - CSR CSTD REQ - Employee Benefits / Non-payroll"
  label var e1b_csrpatntacc "e1b - CSR CSTD REQ - Patient Accounting / Admitting"
  label var e1b_csrothgadm "e1b - CSR CSTD REQ - Other General & Administrative"
  label var e1b_csrnursadm "e1b - CSR CSTD REQ - Nursing Administration"
  label var e1b_csrcentrsr "e1b - CSR CSTD REQ - Central Supply & Services (CSR)"
  label var e1b_csrpharm "e1b - CSR CSTD REQ - Pharmacy"
  label var e1b_csrmedreco "e1b - CSR CSTD REQ - Medical Records"
  label var e1b_csrsocserv "e1b - CSR CSTD REQ - Social Services"
  label var e1b_csrnursged "e1b - CSR CSTD REQ - Nursing Education"
  label var e1b_csrapgradme "e1b - CSR CSTD REQ - Approved Graduate Medical Education"
  label var e1b_csrraddiag "e1b - CSR CSTD REQ - Radiology-Diagnostic"
  label var e1b_csrcomptom "e1b - CSR CSTD REQ - Computerized Tomography"
  label var e1b_csrmrimag "e1b - CSR CSTD REQ - Magnetic Resonance Imaging (MRI)"
  label var e1b_csrradther "e1b - CSR CSTD REQ - Radiology-Therapeutic"
  label var e1b_csrnuclmed "e1b - CSR CSTD REQ - Nuclear Medicine"
  label var e1b_csrlabserv "e1b - CSR CSTD REQ - Laboratory Services"
  label var e1b_csranesth "e1b - CSR CSTD REQ - Anesthesiology"
  label var e1b_csrelectr "e1b - CSR CSTD REQ - Electrocardiography (ECG)"
  label var e1b_csrcardcat "e1b - CSR CSTD REQ - Cardiac Catheterization"
  label var e1b_csrmedsold "e1b - CSR CSTD REQ - Medical Supplies Sold"
  label var e1b_csrdrgsold "e1b - CSR CSTD REQ - Drugs Sold"
  label var e1b_csremergse "e1b - CSR CSTD REQ - Emergency Services"
  label var e1b_csrclinser "e1b - CSR CSTD REQ - Clinic Services"
  label var e1b_csrfreestc "e1b - CSR CSTD REQ - Free Standing Clinic"
  label var e1b_csrnpgradme "e1b - CSR CSTD REQ - Nonapproved Graduate Medical Education"
  label var e1b_csrresearch "e1b - CSR CSTD REQ - Research"

  label var e1b_phartotstats "e1b - Pharmacy CSTD REQ - Total Statistics (Lines 2 through 64)"
  label var e1b_pharemplben  "e1b - Pharmacy CSTD REQ - Employee Benefits / Non-payroll"
  label var e1b_pharpatntacc "e1b - Pharmacy CSTD REQ - Patient Accounting / Admitting"
  label var e1b_pharothgadm "e1b - Pharmacy CSTD REQ - Other General & Administrative"
  label var e1b_pharnursadm "e1b - Pharmacy CSTD REQ - Nursing Administration"
  label var e1b_pharcentrsr "e1b - Pharmacy CSTD REQ - Central Supply & Services (CSR)"
  label var e1b_pharpharm "e1b - Pharmacy CSTD REQ - Pharmacy"
  label var e1b_pharmedreco "e1b - Pharmacy CSTD REQ - Medical Records"
  label var e1b_pharsocserv "e1b - Pharmacy CSTD REQ - Social Services"
  label var e1b_pharnursged "e1b - Pharmacy CSTD REQ - Nursing Education"
  label var e1b_pharapgradme "e1b - Pharmacy CSTD REQ - Approved Graduate Medical Education"
  label var e1b_pharraddiag "e1b - Pharmacy CSTD REQ - Radiology-Diagnostic"
  label var e1b_pharcomptom "e1b - Pharmacy CSTD REQ - Computerized Tomography"
  label var e1b_pharmrimag "e1b - Pharmacy CSTD REQ - Magnetic Resonance Imaging (MRI)"
  label var e1b_pharradther "e1b - Pharmacy CSTD REQ - Radiology-Therapeutic"
  label var e1b_pharnuclmed "e1b - Pharmacy CSTD REQ - Nuclear Medicine"
  label var e1b_pharlabserv "e1b - Pharmacy CSTD REQ - Laboratory Services"
  label var e1b_pharanesth "e1b - Pharmacy CSTD REQ - Anesthesiology"
  label var e1b_pharelectr "e1b - Pharmacy CSTD REQ - Electrocardiography (ECG)"
  label var e1b_pharcardcat "e1b - Pharmacy CSTD REQ - Cardiac Catheterization"
  label var e1b_pharmedsold "e1b - Pharmacy CSTD REQ - Medical Supplies Sold"
  label var e1b_phardrgsold "e1b - Pharmacy CSTD REQ - Drugs Sold"
  label var e1b_pharemergse "e1b - Pharmacy CSTD REQ - Emergency Services"
  label var e1b_pharclinser "e1b - Pharmacy CSTD REQ - Clinic Services"
  label var e1b_pharfreestc "e1b - Pharmacy CSTD REQ - Free Standing Clinic"
  label var e1b_pharnpgradme "e1b - Pharmacy CSTD REQ - Nonapproved Graduate Medical Education"
  label var e1b_pharresearch "e1b - Pharmacy CSTD REQ - Research"

  label var e1b_asttotstats "e1b - Assigned time - Total Statistics (Lines 2 through 64)"
  label var e1b_astemplben  "e1b - Assigned time - Employee Benefits / Non-payroll"
  label var e1b_astpatntacc "e1b - Assigned time - Patient Accounting / Admitting"
  label var e1b_astothgadm "e1b - Assigned time - Other General & Administrative"
  label var e1b_astnursadm "e1b - Assigned time - Nursing Administration"
  label var e1b_astcentrsr "e1b - Assigned time - Central Supply & Services (CSR)"
  label var e1b_astpharm "e1b - Assigned time - Pharmacy"
  label var e1b_astmedreco "e1b - Assigned time - Medical Records"
  label var e1b_astsocserv "e1b - Assigned time - Social Services"
  label var e1b_astnursged "e1b - Assigned time - Nursing Education"
  label var e1b_astapgradme "e1b - Assigned time - Approved Graduate Medical Education"
  label var e1b_astraddiag "e1b - Assigned time - Radiology-Diagnostic"
  label var e1b_astcomptom "e1b - Assigned time - Computerized Tomography"
  label var e1b_astmrimag "e1b - Assigned time - Magnetic Resonance Imaging (MRI)"
  label var e1b_astradther "e1b - Assigned time - Radiology-Therapeutic"
  label var e1b_astnuclmed "e1b - Assigned time - Nuclear Medicine"
  label var e1b_astlabserv "e1b - Assigned time - Laboratory Services"
  label var e1b_astanesth "e1b - Assigned time - Anesthesiology"
  label var e1b_astelectr "e1b - Assigned time - Electrocardiography (ECG)"
  label var e1b_astcardcat "e1b - Assigned time - Cardiac Catheterization"
  label var e1b_astmedsold "e1b - Assigned time - Medical Supplies Sold"
  label var e1b_astdrgsold "e1b - Assigned time - Drugs Sold"
  label var e1b_astemergse "e1b - Assigned time - Emergency Services"
  label var e1b_astclinser "e1b - Assigned time - Clinic Services"
  label var e1b_astfreestc "e1b - Assigned time - Free Standing Clinic"
  label var e1b_astnpgradme "e1b - Assigned time - Nonapproved Graduate Medical Education"
  label var e1b_astresearch "e1b - Assigned time - Research"

* 7. Drop remaining variables
  drop NURSING_FTE*
  drop CSR_CSTD_REQ*
  drop PHARMACY_CSTD_REQ*
  drop ASSIGNED_TIME*

* 8. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check

* 9. Save
  save ${sheets}fl_`i'_E1b.dta, replace
  clear
}  
  

  
  

*===============================================================================
* 13. Extract X1 info - ANALYSIS OF EMPLOYEE BENEFITS
*===============================================================================

forvalues i=2004(1)2020 {

* 1. Import C4 sheet 
  import excel ${data}FY_`i'/FY_`i'_Data.xls, sheet("QUV_SUB_X1") firstrow allstring clear
  describe // Data Check
  summarize // Data Check

* 2. Create start and end dates for reporting period (from SUBMISSION_NUMBER) 
  generate report_from=substr(SUBMISSION_NUMBER,9,8)
  generate report_to=substr(SUBMISSION_NUMBER,17,8)
  generate year=substr(report_to,5,.)

* 3. Pick the most recent record per hospital
  generate latest_date=date(report_from,"MDY")
  bysort FILE_NBR: egen max_date=max(latest_date)
  keep if max_date==latest_date
  drop max_date latest_date

* 4. Drop observationsfrom other years
  tabulate year
  keep if year=="`i'"
 
* 5. Drop duplicate hospital observations
  // Each hospital has multiple rows and each row is a different variable  
  bysort FILE_NBR LINE_NO: ge N=_N
  tabulate N
  bysort FILE_NBR LINE_NO: drop if _n>1

* 6. Drop unnecessary variables
  drop CLIENT_CODE N SUBMISSION_NUMBER report_to report_from

* 7. Reshape Data
  // Reshape data such that each hospital has one row and multiple column variables
  destring LINE_NO, force replace 
  reshape wide AMOUNT, i(FILE_NBR) j(LINE_NO)
  describe // Data Check
  summarize // Data Check

* 8. Keep relevant variables 
  keep FILE_NBR AMOUNT2-AMOUNT12
  describe // Data Check

* 9. Renaming & labeling variables 
  rename FILE_NBR faclnbr

  rename AMOUNT2 x1_ficaemp
  rename AMOUNT3 x1_ficapemp
  rename AMOUNT4 x1_unempins
  rename AMOUNT5 x1_grhltins
  rename AMOUNT6 x1_grlifins
  rename AMOUNT7 x1_pensreti
  rename AMOUNT8 x1_workrins
  rename AMOUNT9 x1_unionwel
  rename AMOUNT10 x1_othrprll
  rename AMOUNT11 x1_emplyben
  rename AMOUNT12 x1_totalben

  label var x1_ficaemp "FICA - Employer's Portion"
  label var x1_ficapemp "FICA - Employee's Portion (Paid by Employer)"
  label var x1_unempins "State and Federal Unemployment Insurance"
  label var x1_grhltins "Group Health Insurance"
  label var x1_grlifins "Group Life Insurance"
  label var x1_pensreti "Pension and Retirement"
  label var x1_workrins "Worker's Compensation Insurance"
  label var x1_unionwel "Union Health and Welfare"
  label var x1_othrprll "Other Payroll Related Employee Benefits"
  label var x1_emplyben "Employee Benefits - Nonpayroll Related (1)"
  label var x1_totalben "Total Employee Benefits"
  

* 10. Arrange and re-check dataset
  sort faclnbr
  describe // Data Check
  summarize // Data Check
  list in 1/10

* 11. Save
  save ${sheets}fl_`i'_X1.dta, replace
  clear
 
 
}



  
*************************
  display c(current_time)
  log close

