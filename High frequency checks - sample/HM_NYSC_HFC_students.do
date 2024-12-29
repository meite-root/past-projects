/*------------------------------------------------------------------------------
High Frequency Checks for the Endline data collection NYSC Project
-------------------------------------------------------------------------------*/


* TODO:
// Duration per section !!!!!!
// Export observations with Arm surveyed/assigned mismatch
// Extra checks 
// Large piece of code left commented out

 
*===============================================================================
* 0. Set Stata work environment
*===============================================================================

  clear all
  version 16
  set more off
  cap log close

* Set path
  global path "/Users/hassanemeite/Documents/ASE:Hunter_College/HFC_NYSC"
  //global path "C:/Users/HP/Desktop/ASE_Project/RISE/Output_FPE_Benin"

* Set folder subdirectories
  cap mkdir "${path}/hfc_output"
  global inputs "${path}/hfc_inputs"
  global output "${path}/hfc_output"
  global data "${path}/raw_data"

* Initialize log
  cd "$path"
  log using ${output}/HFC.log, replace


*===============================================================================
* 1. Loading the data
*===============================================================================

* 1.Load  pretest dataset
  // use "${path}Pretest Endline Student_WIDE.dta", clear
  import excel "${inputs}/NYSC Endline Student_WIDE_26Jul2022.xlsx", sheet("data") firstrow clear  
  
* 2. Narrowing down to the period of interest
  gen submission = string(SubmissionDate, "%tc")
  gen submissiontime = substr(submission,1,9)
  keep if submissiontime == "26jul2022"

* 3. Merge in with enumarator names
  merge m:1 en_enum_id using ${inputs}/enum_id_names.dta, nogen keep(3)
  
  
* 4. Key variables to export when there are errors
  global id_error en_enum_id en_enum_name en_state_name si_school_lga ///
  si_school st_class st_arm_name st_class_type ///
  st_state_orig SubmissionDate starttime endtime cl_comments
  order $id_error
  
* 5. Variables to export when there is no error  
  gen No_issue_to_report = ""
  


*===============================================================================
* 2. Duplicate Checks
*===============================================================================

*-----------------------A. NAME duplicates --------------------------*

* 1. Combine names into one name
  gen whole_name = st_name_sur + " " + st_name_first + " " + st_name_middle 
  gen u_whole_name = upper(whole_name)

* 2. Check duplicates
  duplicates tag whole_name, g(dup_u_whole_name)
  egen check = mean(dup_u_whole_name)

* 3. Export duplicates
  
  if check>0 {
  export excel $id_error op_student_id whole_name dup_u_whole_name ///
  using "$output/duplicates.xlsx" if dup_u_whole_name != 0, ///
  sheet("dup_student_name", replace) firstrow(var)
  *keep if dup_whole_name == 0
  }
  else {
  export excel No_issue_to_report ///
  using "$output/duplicates.xlsx", ///
  sheet("dup_student_name", replace) firstrow(var)
  display " No issue to report "
  }
  drop check
  

  
*-----------------------B. KEY duplicates --------------------------*

* 1. Check duplicates for KEY variable
  duplicates tag KEY, g(dup_key)
  egen check = mean(dup_key)


* 2. Export duplicates 
  if check>0 {
  export excel $id_error op_student_id KEY dup_key ///
  using "$output/duplicates.xlsx" if dup_key != 0, ///
  sheet("dup_submission_key", replace) firstrow(var)
  }
  else {
  export excel No_issue_to_report ///
  using "${output}/duplicates.xlsx", ///
  sheet("dup_submission_key", replace) firstrow(var)
  display " No issue to report "
  }
  drop check 
  



*===============================================================================
* 3. Data Missing Checks
*===============================================================================

*-----------------------A. GPS missing --------------------------*  

* 0.
  gen flag_gpsmiss = (en_gps_acc5Latitude ==.| en_gps_acc5Longitude == .)
  egen check = mean(flag_gpsmiss)
  
* 1. Export observations with missing GPS info  
  if check >0 {
  export excel $id_error en_gps_acc5Latitude ///
  en_gps_acc5Longitude using "$output/data_missing.xlsx" if flag_gpsmiss==1, ///
  sheet("gps_missing", replace) firstrow(var)
}
  else {
  export excel No_issue_to_report ///
  using "$output/data_missing.xlsx", ///
  sheet("gps_missing", replace) firstrow(var)
  }
  drop check 


  
  
*===============================================================================
* 4. Survey correctness Checks
*===============================================================================


*-----------------------A. Class --------------------------*

* 0.
  gen reflg_class = (st_class != 2)
  egen check = mean(reflg_class)
  
* 1. Export observations with incorrect class interviewed
  if check>0{
    export excel $id_error st_class ///
    using "$output/survey_correctness.xlsx" if reflg_class==1, ///
    sheet("class_mismatch", replace) firstrow(var)
  }
  else {
    export excel No_issue_to_report ///
    using "$output/survey_correctness.xlsx", ///
    sheet("class_mismatch", replace) firstrow(var)
  }
  drop check



  
*-----------------------B. Student Age --------------------------*

* 0. Create red flag variable for age outside the normal range
  gen reflg_age = st_age <= 12 | st_age  >= 25
  egen check = mean(reflg_age)
  
* 1. Export observations with age range outside our normal range (12-25)  
  if check>0 {
    export excel $id_error st_age ///
    using "$output/survey_correctness.xlsx" if reflg_age == 1, ///
    sheet("prob_age", replace) firstrow(var)
  }
   else {
    export excel No_issue_to_report ///
    using "$output/survey_correctness.xlsx", ///
    sheet("prob_age", replace) firstrow(var)
  }
  drop check


  
*----------------  C. Duration Extremes  ------------------*  

* 0. Base check 
  summarize duration, detail
  extremes duration
  
* 1. Create red flag variable for duration outside the normal range
  gen flag_duration = duration <= 15*60 | duration >= 35*60
  egen check = mean(flag_duration)
  gen duration_mins = duration / 60
   
* 2. Export observations for inspection
  if check>0 {
    export excel $id_error duration duration_mins ///
	si_treatment_arm_name  ///
    using "$output/survey_correctness.xlsx" if flag_duration == 1, ///
    sheet("duration", replace) firstrow(var)
  }
   else {
    export excel No_issue_to_report ///
    using "$output/survey_correctness.xlsx", ///
    sheet("duration", replace) firstrow(var)
  }
  drop check  

 
  
  

*===============================================================================
* 5. DATA Counts
*===============================================================================

*-----------------------A. NUMBER OF STUDENTS BY SCHOOL --------------------------*

* 1. Generate number of surveys per school
  bysort si_school: egen n_surveys= count (si_school)
  egen tag= tag(si_school)

* 2. Export  
  export excel si_school n_surveys ///
  using "$output/data_counts.xlsx" if tag==1, ///
  sheet("surveys_per_school", replace) firstrow(var)
  drop n_surveys tag


*-----------------------B. ENUMERATOR PERFORMANCE --------------------------*

* 1. Generate number of surveys per enumerator
  bysort en_enum_id: egen n_surveys = count (si_school)
  egen tag= tag(en_enum_id)

* 2. Export
  export excel en_enum_id n_surveys ///
  using "$output/data_counts.xlsx" if tag ==1, ///
  sheet("surveys_per_enum", replace) firstrow(var)
  drop n_surveys tag


  
  
  
*===============================================================================
* 6. Logic checks
*===============================================================================


*-----------------------A. parents education --------------------------*

* 1. Generate flags for contradic. btwn reported Educ. level and higher Ed completion
  gen prob_fat_ed = 1 if ///
  ((ed_relative_count ==0) & (ed_father == 10 | ed_father == 11 | ed_father == 10)) 
  gen prob_moth_ed = 1 if ///
  ((ed_relative_count ==0) & (ed_mother == 10 | ed_mother == 11 | ed_mother == 10))
  gen flagpar_ed= prob_moth_ed ==1 | prob_fat_ed == 1
  egen check = mean(flagpar_ed)

* 2. Export faulty observations 
  if  check >0 {
    export excel $id_error prob_fat_ed prob_moth_ed ///
    ed_father ed_mother ed_relative_count ///
    using "$output/logic_checks.xlsx" if flagpar_ed==1, ///
    sheet("prob_parents_education", replace) firstrow(var)
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("prob_parents_education", replace) firstrow(var)
    display " No issue to report "
  }
  drop check prob_fat_ed prob_moth_ed
  

*-----------------------B. aspirations --------------------------*

* 1. Expected level of education > Wished level of education
  gen flagasp_ed= as_expect_ed > as_wish_ed
  egen check = mean(flagasp_ed)
  if check > 0 {
    export excel $id_error as_wish_ed as_expect_ed ///
    using "$output/logic_checks.xlsx" if flagasp_ed == 1, ///
    sheet("prob_aspiration_ed", replace) firstrow(var)
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("prob_aspiration_ed", replace) firstrow(var)
  }
  drop check

  
* 2. Expected level of Income > Wished level of Income
  gen flagasp_inc = as_expect_income > as_wish_income 
  egen check = mean(flagasp_inc)
  if check > 0 {
    export excel $id_error as_wish_income as_expect_income ///
    using "$output/logic_checks.xlsx" if flagasp_inc==1, ///
    sheet("prob_aspiration_income", replace) firstrow(var)
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("prob_aspiration_income", replace) firstrow(var)
  }  
  drop check

  
* 3. Expected Vocation > Wished Vocation
  gen flagasp_voc = (as_wish_voc == 0 & as_expect_voc ==1) 
  egen check = mean(flagasp_voc)
  if check > 0 { 
    export excel $id_error as_wish_voc as_expect_voc ///
    using "$output/logic_checks.xlsx" if flagasp_voc==1, ///
    sheet("prob_aspiration_voc_train", replace) firstrow(var)
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("prob_aspiration_voc_train", replace) firstrow(var)
  }
  drop check

* 4. Wished Income too low 
  gen flagasp_lwinc = ((as_expect_income < 5000) | (as_wish_income < 5000)) 
  egen check = mean(flagasp_lwinc)
  if check > 0 {
    export excel $id_error as_wish_income_re ///
    as_wish_income as_expect_income as_expect_income_re ///
    using "$output/logic_checks.xlsx" if flagasp_lwinc==1 , ///
    sheet("consistency_income", replace) firstrow(var)
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("consistency_income", replace) firstrow(var)
  }
  drop check

* 5. Vocation inconsistency  
  gen flagasp_wrk = (((as_wish_work == 1) | (as_wish_work == 2) | (as_wish_work == 5)) & ///
  ((as_expect_work == 4) | (as_expect_work == 6) | (as_expect_work == 7)))
  egen check = mean(flagasp_wrk)
  if check > 0 {
    export excel $id_error as_expect_work as_wish_work ///
    using "$output/logic_checks.xlsx" if flagasp_wrk==1, ///
    sheet("prob_aspiration_work", replace) firstrow(var)
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("prob_aspiration_work", replace) firstrow(var)
  }
  drop check

* 6. Owning an interprise - inconsistency 
  gen flagasp_ent = (as_wish_enterprise == 0 & as_expect_enterprise ==1)
  egen check = mean(flagasp_ent)
  if check > 0 {
    export excel $id_error as_wish_enterprise as_expect_enterprise ////
    using "$output/logic_checks.xlsx" if flagasp_ent==1, ///
    sheet("prob_aspiration_enterprise", replace) firstrow(var)
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("prob_aspiration_enterprise", replace) firstrow(var)
  }
  drop check


*-----------------------C. Agreement or not --------------------------*

* 1. Inconsistency: Equality boys and girls
  gen flaggend1 = (bs_gender_1 ==5 & bs_gender_2 ==5)
  egen check = mean(flaggend1)
  if check > 0 {
    export  excel  $id_error bs_gender_1 bs_gender_2 ///
    using "$output/logic_checks.xlsx" if flaggend1==1, ///
    datestring("%tc") firstrow(varl) ///
    sheet("gender_agreement1") sheetreplace 
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("gender_agreement1") sheetreplace 
  }
  drop check
  
* 2. Inconsistency: 
  gen flaggend2 =  ((bs_gender_1 ==5 & bs_gender_2 ==5 & bs_gender_3 ==5 & bs_gender_4 ==5) | ///
  (bs_gender_1 ==1 & bs_gender_2 ==1 & bs_gender_3 ==1 & bs_gender_4 ==1)) 
  egen check = mean(flaggend2)
  if check > 0 {
    export  excel $id_error bs_gender_1 ///
	bs_gender_2 bs_gender_3 bs_gender_4 ///
	using "$output/logic_checks.xlsx" if flaggend2==1, ///
	datestring("%tc") firstrow(varl) ///
	sheet("gender_agreement2") sheetreplace 
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("gender_agreement2") sheetreplace 
  }
  drop check

* 3. Inconsistency: 
  gen flaggov1=(lm_stmt_1 ==5 & lm_stmt_2 ==5)
  egen check = mean(flaggov1)
  if check > 0 {
    export excel $id_error lm_stmt_1 ///
    lm_stmt_2 lm_stmt_3 lm_stmt_4 ///
    using "$output/logic_checks.xlsx" if flaggov1==1, ///
	datestring("%tc") firstrow(varl) ///
	sheet("gov1") sheetreplace 
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("gov1") sheetreplace 
  }
  drop check
  
* 4. Inconsistency: 
  gen flaggov2= ((lm_stmt_1 ==5 & lm_stmt_2 ==5 & lm_stmt_3 ==5 &lm_stmt_4 ==5) | ///
  (lm_stmt_1 ==1 & lm_stmt_2 ==1 & lm_stmt_3 ==1 & lm_stmt_4 ==1))
  egen check = mean(flaggov2)
  if check > 0 {
    export  excel  $id_error lm_stmt_1 ///
    lm_stmt_2 lm_stmt_3 lm_stmt_4 ///
    using  "$output/logic_checks.xlsx" if flaggov2==1, ///
	datestring("%tc") firstrow(varl) ///
	sheet("gov2") sheetreplace 
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("gov2") sheetreplace 
  }
  drop check
  
  
*-----------------------D. attending the session --------------------------*

* 1. Inconsistency:
  gen flagsess1 =(ms_training_and_followup ==5 & ms_gave_best ==1)
  egen check = mean(flagsess1)
  if check > 0 {
    export excel $id_error ms_training_and_followup ms_gave_best ///
    using "$output/logic_checks.xlsx" if flagsess1==1, ///
    datestring("%tc") firstrow(varl) sheet("session") sheetreplace 
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("session") sheetreplace  
  }
  drop check
  
* 2. Inconsistency:  
  gen flagsess2 = (ms_training_and_followup ==5 & ms_learned_lot==5 & ms_gave_best ==5 & ///
  ms_challenges_admin ==5 & ms_challenges_students==5)
  egen check = mean(flagsess2)
  if check > 0 {
    export excel $id_error ms_learned_lot ms_training_and_followup ///
    ms_gave_best ms_challenges_admin ms_challenges_students ///
    using "$output/logic_checks.xlsx" if flagsess2==1, ///
	datestring("%tc") firstrow(varl) sheet("session2") sheetreplace 
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("session2") sheetreplace  
  }  
  drop check
  

* 3. Inconsistency:
  gen flagsess3 = (ms_training_and_followup ==1 & ms_learned_lot==1 & ms_gave_best ==1 & ///
  ms_challenges_admin ==1 & ms_challenges_students==1)
  egen check = mean(flagsess3)
  if check > 0 {
    export excel $id_error ms_learned_lot ms_training_and_followup ///
    ms_gave_best ms_challenges_admin ms_challenges_students ///
    using "$output/logic_checks.xlsx" if flagsess3==1, ///
	datestring("%tc") firstrow(varl) sheet("session3") sheetreplace 
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("session3") sheetreplace  	
  }
  drop check
  
* 4. Inconsistency:  
  gen flagsess4= (ms_training_and_followup ==96 & ms_learned_lot==96 & ms_gave_best ==96 ///
  & ms_challenges_admin ==96 & ms_challenges_students==96)
  egen check = mean(flagsess4)
  if check > 0 {
    export excel $id_error ms_learned_lot ms_training_and_followup ///
    ms_gave_best ms_challenges_admin ms_challenges_students ///
    using "$output/logic_checks.xlsx" if flagsess4==1, ///
	datestring("%tc") firstrow(varl) sheet("session4") sheetreplace 
  }
  else {
    export excel No_issue_to_report ///
    using "$output/logic_checks.xlsx", ///
    sheet("session4") sheetreplace  
  }
  drop check
  

 

 
 
 
 
*===============================================================================
* 7. Interview duration
*===============================================================================

/*
* 1. Correct for outliers first
//   ssc install extremes 
  summarize duration, detail
  extremes duration



* 2. Generate mean by interviewer: dureemoy
  bysort en_enum_id_re: egen dureemoy = mean(duration)
  bysort en_enum_id_re: tab dureemoy // Visualize dureemoy

* 3. Generate mean overall of interview durations: mean
  egen mean = mean(duration)
  
* 4. Generate standard deviation of overall of interview durations: sd
  egen sd = sd(duration)
  *replace sd = round(sd,.1)


*br Num_Enq dureemoy mean diff percdiff sd sds 

**** Identify  one observation that will be used of each interviwer***
egen tag1 = tag(en_enum_id_re)

lab var dureemoy "Average Interview Duration for Interviewer"
lab var mean "Average Interview Duration for all Interviewers"
lab var sd "Standard Deviation of Mean"


* Find out the enumerators that are extremely over or less of the average time 

gen flag0 = (duration < 300)
gen flag1 = (dureemoy > (mean + sd)) 
gen flag2 = (dureemoy < (mean - sd)) 
lab var flag2 "<1 Std. Devs. Different from Mean"
lab var flag1 ">1 Std. Devs. Different from Mean"
*br dureemoy mean sd tag1 flag1 flag2


export excel  $id_error dureemoy mean sd tag1 flag1 flag2 using "$output/duration.xls" ///
if (tag1 == 1 & flag1 == 1) |(tag1 == 1 & flag2 == 1), datestring("%tc") firstrow(varl) sheet("dureemoy") sheetreplace 
*drop if duration_interview < 0
*/

  
/*
import excel "G:/My Drive/RISE_Project/NYSC/Endline HFC/NYSC Endline Corper_WIDE.xlsx", sheet("data") firstrow clear

// Count number of corpers surveyed per school

bys si_school: egen n_corp_school = count (bi_corper_name)
egen tag4= tag (si_school)

export excel si_school n_corp_school using "$output/school_sum.xlsx" if tag4 ==1, sheet("n_corp_school)", replace) firstrow(var)


import excel "G:/My Drive/RISE_Project/NYSC/Endline HFC/hfc_output/school_sum.xlsx", sheet("n_corp_school)") firstrow clear

import excel "G:/My Drive/RISE_Project/NYSC/Endline HFC/hfc_output/school_sum.xlsx", sheet("n_stu_school)") firstrow clear

merge 1:1 si_school using "G:/My Drive/RISE_Project/NYSC/Endline HFC/n_corp_school.dta", force


import excel "G:/My Drive/RISE_Project/NYSC/Endline HFC/NYSC Endline School_WIDE.xlsx", sheet("data") firstrow clear

duplicates tag si_school, g(dup_si_school)
egen tag2= tag (si_school)

export excel si_school si_count_sss2 sir_count_surveyed_1 sir_count_present_1 sir_count_surveyed_2 sir_count_present_2 sir_count_surveyed_3 sir_count_present_3 using "$output/school_class_stu.xlsx", sheet("n_class_stu_school)", replace) firstrow(var)
e
keep if tag ==1

merge 1:1 si_school using "G:/My Drive/RISE_Project/NYSC/Endline HFC/n_stu_corp_school.dta", force

export excel si_school n_corp_school n_stu_school dup_si_school using "$output/school_sum.xlsx", sheet("n_corp_stu_school2)", replace) firstrow(var)

e
bys en_enum_id: egen n_school = count (si_school)
egen tagenum_scho= tag(en_enum_id)

export excel en_enum_id n_school using "$output/nbr_school.xlsx" if tagenum_scho ==1, sheet("n_enum_school)", replace) firstrow(var)


import excel "G:/My Drive/RISE_Project/NYSC/Endline HFC/NYSC Endline School_WIDE.xlsx", sheet("data") firstrow clear

*/


  
/*  
*-----------------------E. number of survey by school --------------------------*
 ///////
*gen school_name = Awotan Araromi Community High School Snr if *si_school ==  20101
table en_state_name
table si_school

merge m:1 si_school using "$path/school _id.dta", nogenerate force

/// enumarator performance
table en_enum_id
br en_enum_id si_school 
bys en_enum_id: tab si_school

export excel using data_all, datestring("%tc") firstrow(varl) sheet("dureemoy") sheetreplace 
*drop if duration_interview < 0
*/



/* additionnals checkings
*duplicates id and difference in the names
* check the classroom they need to survey, check if they are surveying the right class, and following the protocol
* agrement: do you like your 
*for the same question on strongly agree, for instance if you like your teacher and if your teacher is kind.  
* percent of percent of don't and refuse, not applicable.
*check if 

* self employed: how many wish
every student should be SS2: the range is wide  anything greater 25 and lower than 12

///School survey
what they are reporting in the school is consistent with what they have surveyed
*/
