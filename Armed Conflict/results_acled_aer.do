**Run programs
**************


clear all

cd "C:\Users\Hassane\Desktop\School Files -  Spring 2020\Final Capstone Project\complete dataset\Stelios_replica"
use aer_all2013.dta

encode wbcode, gen(ccode)
xtset ccode


set more off


** Conditioning Sets
*********************************************************************************************

global regi 			region_n region_s region_w region_e 

global simple			lnpop60 lnkm2split  lakedum riverdum
global location 		capital borderdist1 capdistance1 seadist1 coastal 
global geo	 			mean_elev mean_suit diamondd malariasuit petroleum island city1400 
global rich1 			mean_elev mean_suit diamondd malariasuit petroleum island city1400 
global suprich  		$simple $location	 $rich1 


** Run the Programs. .do files
***********************************************************************************************
***********************************************************************************************
run cgmreg.ado

** Main Paper
run T2-A.do
run T2-B.do
run T3.do
run T4-A.do
run T4-B.do
run T5.do 
run T6.do

** Supplementary Appendix 
run TA9.do
 
 
*************************************************************************************************************************************************************************
** Appendix Table 9. "Balancedeness Tests." Ethnic Partitioning and Geographic Characteristics within Countries .
** Test of means of all controls in the country-ethnic homeland
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************

** Panel A. All Country-Ethnic Homelands (1212 Obs)
**************************************************************************************************************************************************************************
estout slt_*, cells(b(star fmt(%9.4f)) se(par) p(fmt(%9.2f)))  keep(split10pc  )  ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square))  style(fixed)

** Mean Dependent Variable
	   tabstat  $allvars   if pop60!=0 , stats(mean ) 


** Panel B. Country-Ethnic Homelands close to the National Border (606 Obs)
**************************************************************************************************************************************************************************	   
estout sltc_*, cells(b(star fmt(%9.4f)) se(par) p(fmt(%9.2f)))  keep(split10pc  ) ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square))  style(fixed)

** Mean Dependent Variable	   
	   tabstat  $allvars   if pop60!=0 & borderdist1<median_bd, stats(mean )  
 

*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
**** Appendix Table 2. Summary Statistics. ACLED 4.
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
global acled 		all alld dur fatal allf allfd durd allm allmd    durm  battles batd vio viod riots riotsd 
global acledmore 	govt govtd rebmil rebmild   riotprot riotprotd civilians civiliansd intervention interventiond outside outsided

** Panel A. All Country-Ethnic Homelands
*********************************************************************************************************************
tabstat $acled 		if pop60!=0 , stats(n mean sd p50 min p90 max) col(stats)
tabstat $acledmore 	if pop60!=0 , stats(n mean sd p50 min p90 max) col(stats)

** Panel B: Homelands close to the National Border
*********************************************************************************************************************
tabstat $acled 		if pop60!=0 & borderdist1<median_bd  , stats(n mean sd p50 min p99 max) col(stats)
tabstat $acledmore 	if pop60!=0 & borderdist1<median_bd  , stats(n mean sd p50 min p99 max) col(stats)
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
	  
	  
	
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
**** Appendix Table 7. Correlation Structure - Main Conflict Variables (ACLED and UCDP)
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************  
pwcorr all allf fatal dur durdead battles vio riots sum_state_no sum_onesided_no sum_nonstate_no, star(0.05)	  
	  
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
*** Table 2. Baseline Country Fixed-Effects Estimates (ACLED).
*** Panel A. Negative Binomial ML Estimates with country Fixed-Effects
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
** All events; all ethnic homelands; columns (1)-(6)
*************************************************************************************************************************************************************************
estout alnb1 alnb2 alnb3 alnb4  alnb4 alnb5 alnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)

** All events; ethnic homelands close to the border. columns (7)-(12)
*************************************************************************************************************************************************************************	   
estout alnb1c alnb2c alnb3c alnb4c  alnb4c alnb5c alnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
   

*** Table 2. Baseline Country Fixed-Effects Estimates (ACLED).
*** Panel B. Linear Probability Model (LPM) Estimates with country Fixed-Effects
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
** All events (reported in Panel B-Table 2)
*****************************************************************************************
estout allp1 allp2 allp3 allp4  allp4 allp5 allp6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
** All events; ethnic homelands close to the border. columns (7)-(12)
*************************************************************************************************************************************************************************	
estout allp1c allp2c allp3c allp4c  allp4c allp5c allp6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)

	
 
*******************************************************************************************************************************************************************
*******************************************************************************************************************************************************************	   
** Table 3. Ethnic Partitioning and Civil Conflict Intensity. ACLED. Country Fixed-Effects Estimates.
*********************************************************************************************************************************************************************
*********************************************************************************************************************************************************************
** all specifications: rich set of countrols and country fixed-effects
** columns (1)-(5): All Country-Ethnic Homelands
** columns (6)-(10): Country-ethnic homelands close to the national border
*****************************************************************************************
estout efatnb fallp fatnb tid tdi efatnbc fallpc fatnbc tidc tdic, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll r2a_ N , fmt(%9.3f %9.0g) labels(LogLikelihood adjusted-R2 Obs)) keep(split10pc spil) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
*******************************************************************************************************************************************************************
*******************************************************************************************************************************************************************
** Table 4. Ethnic Partitioning and Civil Conflict Aspects. ACLED
***************************************************************************
** Panel A. Negative Binomial ML Estimates with country Fixed-Effects
***************************************************************************
** all specifications: rich set of countrols and country fixed-effects
** columns (1)-(3): All Country-Ethnic Homelands
** columns (4)-(6): Country-ethnic homelands close to the national border
*********************************************************************************************************************************************************************
estout btnb4 vnbi4  rionbi4 cbtnb4 cvnbi4 crionbi4, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood Obs)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
** Table 4. Panel B. Ethnic Partitioning and Civil Conflict Aspects
** Linear Probability Model (LPM) Estimates with country Fixed-Effects
***********************************************************************
** all specifications: rich set of countrols and country fixed-effects
** columns (1)-(3): All Country-Ethnic Homelands
** columns (4)-(6): Country-ethnic homelands close to the national border
*********************************************************************************************************************************************************************
estout btlp4 vlpi4  riolpi4 cbtlp4 cvlpi4 criolpi4, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square Obs)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)  
	   
	
***************************************************************************************************************************************************************
***************************************************************************************************************************************************************    	   
** Table 5. Ethnic Partitioning and Conflict Actors. ACLED.
***************************************************************************************************************************************************************
***************************************************************************************************************************************************************    
** all specifications: rich set of countrols and country fixed-effects
** columns (1)-(4): All Country-Ethnic Homelands
** columns (5)-(8): Country-ethnic homelands close to the national border
************************************************************************** 
** columns (1) & (5): government
** columns (2) & (6): rebel and militia groups
** columns (3) & (7): interventions of nearby African countries
** columns (4) & (8): outside multinational interventions (UN, NATO, African Union)	   
******************************************************************************************	   
** Panel A: Negative Binomial ML estimates
*****************************************************************************************************************************************************************
estout a1 a4 a8 a9 ac1 ac4 ac8 ac9, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(LogLikelihood Obs)) keep(split10pc spil) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)	   
	
** Panel B: Linear Probability Model (LPM) estimates
****************************************************************************************************************************************************************
estout als1 als4 als8 als9 acls1 acls4 acls8 acls9, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjustedR2 Obs)) keep(split10pc spil) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed) 	   
	   

*****************************************************************************************************************************************************************
** Table 6: Ethnic Partitioning and Civil Conflict Types. UCDP GED
*******************************************************************
*******************************************************************
** columns (1) - (3): All Homelands 
** columns (4) - (6): Country-ethnic Homelands close to the neational border  
** all columns; country FE and rich set of controls
** columns (1) & (4): NB-ML number of events/incidents (deadly) 
** columns (2) & (5): LPM with likelihood of deadly events
** columns (3) & (6): NB-ML duration (in years) of deadly events/incidents
*******************************************************************************************************************************************************************
*******************************************************************************************************************************************************************
** Panel A: State Conflict
*******************************************************************************************************************************************************************
estout st1 st2 st3 st1c st2c st3c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll r2_a N , fmt(%9.3f %9.0g) labels(LogLikelihood R2 Obs)) keep(split10pc   spil) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)

** Panel B: One-Sided Violence against Civilians
*******************************************************************************************************************************************************************
estout os1 os2 os3 os1c os2c os3c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll r2_a N , fmt(%9.3f %9.0g) labels(LogLikelihood R2 Obs)) keep(split10pc   spil) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
** Panel C: Non-State Conflict
*******************************************************************************************************************************************************************
estout ns1 ns2 ns3 ns1c ns2c ns3c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll r2_a N , fmt(%9.3f %9.0g) labels(LogLikelihood R2 Obs)) keep(split10pc   spil) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
	   


** Supplementary Appendix 
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************

** Run the Programs. Robustness Checks
***************************************
***************************************
estimates clear

run TA15-A.do
run TA15-B.do
run TA17.do
run TA18.do
run TA19.do
run TA20.do
run TA21.do
run TA22.do
run TA23.do

run TA25.do
run TA26.do
run TA27.do
run TA28.do

run TA24.do
**************************************
**************************************


*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
*** Appendix Table 15. Ethnic Partitioning and Civil Conflict. Alternative Estimation Techniques. ACLED
*** Panel A. Conditional NB ML Estimates (Hausman, Hahn, and Griliches, 1984) 
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
** All events; all ethnic homelands; columns (1)-(6)
** All events; close to the border country-ethnic homelands; columns (7)-(12)
*************************************************************************************************************************************************************************
estout alxnb1 alxnb2 alxnb3 alxnb4  alxnb4 alxnb5 alxnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil    ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)

estout alxnb1c alxnb2c alxnb3c alxnb4c  alxnb4c alxnb5c alxnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil     ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
   	  

*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
*** Appendix Table 15. Ethnic Partitioning and Civil Conflict. Alternative Estimation Techniques. ACLED
*** Panel B. Fixed-Effects Poisson ML Estimates (excl. Outliers)
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
** All events; all ethnic homelands; columns (1)-(6), (5) ommited
** All events; close to the border country-ethnic homelands; columns (7)-(12); (11) omitted
*************************************************************************************************************************************************************************
estout alpoi1 alpoi2 alpoi3 alpoi4  alpoi5 alpoi1c alpoi2c alpoi3c alpoi4c  alpoi5c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(LogLikelihood Obs)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	  
	   

******************************************************************************************************************************************************************************
******************************************************************************************************************************************************************************
** Appendix Table 16. Ethnic Partitioning and Main Aspects of Civil Conflict. Alternative Estimation Techniques. ACLED
** Panel A. Conditional Negative Binomial ML Estimates (Hausman, Hahn, and Griliches, 1984) 
******************************************************************************************************************************************************************************
******************************************************************************************************************************************************************************
** all ethnic homelands; columns (1)-(3)
** close to the border country-ethnic homelands; columns (4)-(8)
** rich set of controls in all specifications
****************************************************************************************************************************************************************************** 
estout btxnb vxnb rioxnb cbtxnb cvxnb crioxnb, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(LogLikelihood Obs)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)   
	   
** Appendix Table 16. Ethnic Partitioning and Main Aspects of Civil Conflict. Alternative Estimation Techniques
** Panel B. Fixed-Effects Poisson ML Estimates (excl. Outliers)
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
** all ethnic homelands; columns (1)-(3)
** close to the border country-ethnic homelands; columns (4)-(8)
** rich set of controls in all specifications and country fixed-effects
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
estout btxpo vxpoi rioxpoi cbtxpo cxvnbi crioxpoi, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(LogLikelihood Obs)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
	     
** Appendix Table 17. Ethnic Partitioning and Conflict Actors. Poisson ML Estimates with Country Fixed-Effects (excl. outliers). ACLED.
***************************************************************************************************************************************************************
***************************************************************************************************************************************************************
** all specifications: rich set of countrols and country fixed-effects
** columns (1)-(4): All Country-Ethnic Homelands
** columns (5)-(8): Country-ethnic homelands close to the national border
************************************************************************** 
** columns (1) & (5): government
** columns (2) & (6): rebel and militia groups
** columns (3) & (7): interventions of nearby African countries
** columns (4) & (8): outside multinational interventions (UN, NATO, African Union)	   
******************************************************************************************		   
estout apo1 apo4 apo8 apo9 apoc1 apoc4 apoc8 apoc9, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(LogLikelihood Obs)) keep(split10pc spil) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)	
		   
	   
** Appendix Table 18. Ethnic Partitioning and Civil Conflict. Not Accounting for Spillovers. ACLED
***********************************************************************************************************************************************************************
***********************************************************************************************************************************************************************
** outcome varaible. all main events (excl. riots and protests)
** all columns: rich set of controls
** column (1) and (4): all observatins 
** column (2) and (5): dropping outliers
** column (3) and (6): dropping capitals 		
** columns (1)-(3): all ethnic homelads; columns (4)-(6): areas close to the national border
***********************************************************************************************************************************************************************

** Panel A. NB ML Estimates with Country Fixed-Effects. 
************************************************************************************************************************************************************************
estout  fmfroalnb1 fmfroalnb2 fmfroalnb3 fmfroalnb1c fmfroalnb2c fmfroalnb3c, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(  split10pc  ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
	   
** Panel B. Linear Probability Model Estimates with Country Fixed-Effects 
***********************************************************************************************************************************************************************
estout fmfrolp1 fmfrolp2 fmfrolp3  fmfrolp1c fmfrolp2c fmfrolp3c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(  split10pc ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
	   
	   
** Appendix Table 19. Ethnic Partitioning and Civil Conflict. Alternative Measure of Ethnic Partitioning. ACLED
***********************************************************************************************************************************************************************
***********************************************************************************************************************************************************************
** outcome varaible. all main events (excl. riots and protests)
** all columns: rich set of controls
** columns (1) and (4): all observatins 
** columns (2) and (5): dropping outliers
** columns (3) and (6): dropping capitals 		
** columns (1)-(3): all ethnic homelads; columns (4)-(6): areas close to the national border
***********************************************************************************************************************************************************************
** Panel A. NB ML Estimates with Country Fixed-Effects. 
************************************************************************************************************************************************************************
estout  ffroalnb1 ffroalnb2 ffroalnb3 ffroalnb1c ffroalnb2c ffroalnb3c, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(LogLikelihood Obs)) keep(  split5pc  ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)   
	   
** Panel B. Linear Probability Model Estimates with Country Fixed-Effects 
***********************************************************************************************************************************************************************
estout ffrolp1 ffrolp2 ffrolp3  ffrolp1c ffrolp2c ffrolp3c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(  split5pc ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	     

** Appendix Table 20. Ethnic Partitioning and Civil Conflict. Controlling for Unobservables. Distance to the Border. 3rd-order Polynomial. ACLED. 
***********************************************************************************************************************************************************************
***********************************************************************************************************************************************************************
** all columns: rich set of controls; and 3rd-order polynomial on distnace to national the border
** columns (1) and (4): all events 
** columns (2) and (5): battles
** columns (3) and (6): violence against civilians	
** columns (4) and (8):  riots and protests
** columns (1)-(4): all ethnic homelads; columns (5)-(8): areas close to the national border
***********************************************************************************************************************************************************************
** Panel A. Negative Binomial ML with country Fixed-Effects
************************************************************************************************************************************************************************
estout pnn1 pnn2 pnn3 pnn4 pnnc1 pnnc2 pnnc3 pnnc4, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll r2_a N, fmt(%9.3f %9.0g) labels(LogLikelihood Obs)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
** Panel B. Linear Probability Model Estimates with Country Fixed-Effects
************************************************************************************************************************************************************************
estout pa1 pa2 pa3 pa4 pa1c pa2c pa3c pa4c, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N, fmt(%9.3f %9.0g) labels(adjustedR2 Obs)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)	   
	   
** Appendix Table 21. Ethnic Partitioning and Civil Conflict. Controlling for Unobservables. Distance to the Border. 4th-order poly1nomial. ACLED.  
***********************************************************************************************************************************************************************
***********************************************************************************************************************************************************************
** all columns: rich set of controls; and 4th-order polynomial on distnace to national the border
** column (1) and (4): all events 
** column (2) and (5): battles
** column (3) and (6): violence against civilians	
** column (4) and (8):  riots and protests
** columns (1)-(4): all ethnic homelads; columns (5)-(8): areas close to the national border
***********************************************************************************************************************************************************************
** Panel A. Negative Binomial ML with country Fixed-Effects
************************************************************************************************************************************************************************
estout opnn1 opnn2 opnn3 opnn4 opnnc1 opnnc2 opnnc3 opnnc4, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll r2_a N, fmt(%9.3f %9.0g) labels(LogLikelihood Obs)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
** Panel B. Linear Probability Model Estimates with Country Fixed-Effects
************************************************************************************************************************************************************************
estout opa1 opa2 opa3 opa4 opa1c opa2c opa3c opa4c, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N, fmt(%9.3f %9.0g) labels(adjustedR2 Obs)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)

* Appendix Table 22. Ethnic Partitioning and Civil Conflict. Controlling for Unobservables. Ethnic-Family Fixed-Effects Specifications. ACLED.
***********************************************************************************************************************************************************************
***********************************************************************************************************************************************************************
** all columns: rich set of controls
** all columns: country fixed-effects and ethnic family (cluster) fixed effects
** columns (1)-(3): all ethnic homelands; columns (4)-(6): areas close to the national border
***********************************************************************************************************************************************************************
** Panel A. NB-ML, LPM, and Poisson ML estimates using all conflict events (of any type) 
***********************************************************************************************************************************************************************
estout  dd1 dd2 dd3 dd1c  dd2c  dd3c, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll r2_a N , fmt(%9.3f %9.0g) labels(LogLikelihood R2 Obs)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	      
** Panel B. NB-ML, LPM, and Poisson ML estimates using main conflict events (excl. riots-protests) 
***********************************************************************************************************************************************************************
estout ddm1 ddm2 ddm3 ddm1c  ddm2c  ddm3c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll r2_a N , fmt(%9.3f %9.0g) labels(LogLikelihood R2 Obs)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
	   	   
** Appendix Table 23. Ethnic Partitioning and Civil Conflict. Dropping Iteratively a Different African Region. ACLED
***********************************************************************************************************************************************************************
***********************************************************************************************************************************************************************
** outcome varaible. all main events (excl. riots and protests)
** all columns: rich set of controls 	
** Odd-numbered columns: all ethnic homelads; Even-numbered columns: ethnic areas close to the national border
***********************************************************************************************************************************************************************
** NB-ML 
***********************************************************************************************************************************************************************
estout  nonorth1 nonorth2 nosouth1 nosouth2 nowest1 nowest2 noeast1 noeast2 nocentr1     nocentr2, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(LogLikelihood Obs)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
** LPM. OLS linear probability models.
************************************************************************************************************************************************************************
estout nonorth3 nonorth4 nosouth3 nosouth4 nowest3 nowest4 noeast3 noeast4 nocentr3     nocentr4 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   	   

** Appendix Table 24. Ethnic Partitioning and Civil Conflict. Spillovers with Formal Spatail Econometric Tools. ACLED. 
************************************************************************************************************************************************************************
************************************************************************************************************************************************************************
** All specifications; rich set of controls and country fixed-effects
** columns (1)-(3); linear W-matrix
** columns (4)-(6); quadratic W-matrix
** columns (1) & (4): Spatial Lag Model
** columns (2) & (5): Durbin Model
** columns (3) & (6): Generalized Spatial Lag Model
************************************************************************************************************************************************************************
** Panel A. Dependent Variable. Main Events Indicator
************************************************************************************************************************************************************************
estout bgs1 bgs2 bgs3 bgs4 bgs5 bgs6  , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll ll_0 N rho lamda, fmt(%9.3f %9.0g) ) keep(split10pc ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)

** Panel B. Dependent Variable. Ln (1+Number of Main Events)
****************************************************************************************************************************************************************
estout gs5 gs6 gs3 gs4 gs1 gs2   , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll ll_0 N rho lamda, fmt(%9.3f %9.0g) ) keep(split10pc ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)


* Appendix Table 25. Ethnic Partitioning and Civil Conflict. Accounting for spillovers at the Country Level and at the Ethnic Family Level
***********************************************************************************************************************************************************************
***********************************************************************************************************************************************************************
** all specifications: rich set of countrols and region fixed-effects
** columns (1)-(6): All Country-Ethnic Homelands
** columns (7)-(12): Country-ethnic homelands close to the national border
*****************************************************************************************
estout spi1 spi2 spi3 spi4 spi5 spi6 spi1c spi2c spi3c spi4c spi5c spi6c, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll r2a_ N , fmt(%9.3f %9.0g) labels(LogLikelihood adjusted-R2 Obs)) keep(split10pc  lnallm_family	lnallm_country ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
	   
	
** Appendix Table 26. Ethnic Partitioning and Civil Conflict.  Accounting for pre-colonial conflict (slave trades and kingdoms/empires). ACLED
***********************************************************************************************************************************************************************
***********************************************************************************************************************************************************************
** outcome varaible. all main events (excl. riots and protests)
** all columns: rich set of controls and country fixed-effects
** columns (1) & (4); controlling for dummy for pre-colonial  conflcit and log distance to pre-colonial conflict (Besley and Reynal-Querrol)
** columns (2) & (5): controlling for log slave exports, using data and standardization of Nunn (2008) 
** columns (3) & (6): controlling for dummy for pre-colonial 	empire and log distance to empire (Besley and Reynal-Querrol)
** columns (1)-(3): all ethnic homelads; columns (4)-(6): areas close to the national border
************************************************************************************************************************************************************************
** NB-ML with country fixed-effects
*************************************************************************************************************************************************************************
estout  pcw1 pcw5 pcw3  pcw1c  pcw5c pcw3c   , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(LogLikelihood Obs)) keep(  split10pc  spil precondummy lndistcon empire lndistemp lnexports1) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	   
** LP - OLS linear probability models with country fixed-efefcts. CGMREG. 
****************************************************************************************************************************************************************************
estout pcw2 pcw6 pcw4  pcw2c  pcw6c pcw4c   , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjustedR-square Obs)) keep(  split10pc  spil precondummy lndistcon empire lndistemp lnexports1 ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)


** Appendix Table 27. Ethnic Partitioning and Civil Conflict.  Accounting for Regional Development (using data from G-Econ Project). ACLED
***********************************************************************************************************************************************************************
***********************************************************************************************************************************************************************
** all columns: rich set of controls and country fixed-effects and log of GDP p.c in 2000 (G-Econ Project)
** columns (1) & (5); all events
** columns (2) & (6): battles 
** columns (3) & (7): civilian violence
** columns (4) & (8): riots and protests
** columns (1) - (4): all ethnic homelads; columns (5) - (8): areas close to the national border
************************************************************************************************************************************************************************
** Panel A. NB-ML with country fixed-effects
************************************************************************************************************************************************************************
estout wnb1 wnb2 wnb3 wnb4 wnb1c wnb2c wnb3c wnb4c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil wlngcp_pc_mer) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed) 
	   
** Panel B. Linear Probability Model with country fixed-effects
*********************************************************************************************************************************************************************************	   
estout ww1 ww2 ww3 ww4 ww1c ww2c ww3c ww4c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjsuted r-square)) keep(split10pc spil wlngcp_pc_mer) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed) 
   
	   
	   
** Appendix Table 28. Ethnic Partitioning and Civil Conflict Actors.  Accounting for Regional Development (using data from G-Econ Project). ACLED
***********************************************************************************************************************************************************************
***********************************************************************************************************************************************************************
** all columns: rich set of controls and country fixed-effects and log of GDP p.c in 2000 (G-Econ Project)
** Linear Probability Model Estimates
** columns (1) & (7) : government forces
** columns (2) & (8) : rebels and militias 
** columns (3) & (9) : civilian violence
** columns (4) & (10): riots and protests
** columns (3) & (11): external interventions from nearby countries
** columns (4) & (12): external interventions from NATO, AU, etc
** columns (1) - (6): all ethnic homelads; columns (7) - (12): areas close to the national border
************************************************************************************************************************************************************************
estout gals1 gals4 gals5 gals6 gals8 gals9 gacls1 gacls4 gacls5 gacls6 gacls8 gacls9, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjsuted r-square)) keep(split10pc spil wlngcp_pc_mer) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed) 
	




