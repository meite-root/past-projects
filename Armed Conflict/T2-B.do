

** Table 2-Panel B
***********************************************************************************************************************************************************************
***********************************************************************************************************************************************************************
** This .do file runs Linear Probability Models models with the ACLED adta for the Tables in the main part of the paper.
** The LPM specifications are reported in Table 2. Panel B. 
************************************************************************************************************************************************************************
************************************************************************************************************************************************************************


** Preliminaries
*****************
************************************************************************************************************************************************************************
************************************************************************************************************************************************************************

* Notes:
********
** need to download the cgmreg.ado routine that implements the multi-way clustering method of Cameron, Gelbach, and Miller (2011)
** s.e. are clustred at the ethnic family (cluster) and the the country level (wbcode)
************************************************************************************************************************************************************************




** Conditioning Sets
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************

global regi 			region_n region_s region_w region_e 

global simple			lnpop60 lnkm2split  lakedum riverdum
global location 		capital borderdist1 capdistance1 seadist1 coastal 
global geo	 			mean_elev mean_suit diamondd malariasuit petroleum island city1400 
global rich1 			mean_elev mean_suit diamondd malariasuit petroleum island city1400 





** Estimate Baseline Regressions. Dependent Variable. Indicator for country-ethnic homelands experencing a conflcit event (of any type)
*************************************************************************************************************************************************************************
** Linear Probability Models with CGMREG
******************************************
******************************************
*************************************************************************************************************************************************************************

*** All Events.
xi: cgmreg alld  	split10pc spil 		$simple                     					,  cluster(wbcode  cluster)
est store allp1

xi: cgmreg alld  	split10pc spil 		$simple                  i.wbcode				,  cluster(wbcode  cluster)
est store allp2

xi: cgmreg alld 	split10pc spil 		$simple         $location i.wbcode				,  cluster(wbcode  cluster)
est store allp3

xi: cgmreg alld 	split10pc spil 		$simple  $rich1 $location i.wbcode				,  cluster(wbcode  cluster)
est store allp4

xi: cgmreg alld 	split10pc spil		$simple  $rich1 $location i.wbcode if all<top_all,  cluster(wbcode  cluster)
est store allp5

xi: cgmreg alld 	split10pc spil 		$simple  $rich1 $location i.wbcode if capital==0,  cluster(wbcode  cluster)
est store allp6

**
xi: cgmreg alld  	split10pc spil 		$simple                           if borderdist1<median_bd  & no==0					,  cluster(wbcode  cluster)
est store allp1c

xi: cgmreg alld  	split10pc spil 		$simple                   i.wbcode if borderdist1<median_bd  & no==0				,  cluster(wbcode  cluster)
est store allp2c

xi: cgmreg alld 	split10pc spil 		$simple         $location i.wbcode if borderdist1<median_bd  & no==0				,  cluster(wbcode  cluster)
est store allp3c

xi: cgmreg alld 	split10pc spil 		$simple  $rich1 $location i.wbcode if borderdist1<median_bd  & no==0				,  cluster(wbcode  cluster)
est store allp4c

xi: cgmreg alld 	split10pc spil 		$simple  $rich1 $location i.wbcode if all<top_all & borderdist1<median_bd  & no==0	,  cluster(wbcode  cluster)
est store allp5c

xi: cgmreg alld 	split10pc spil 		$simple  $rich1 $location i.wbcode if capital==0 & borderdist1<median_bd  & no==0	,  cluster(wbcode  cluster)
est store allp6c


*** All Main Events (excluding Riots and Protests); Not-Reported
*******************************************************************************************************************************************************************
xi: cgmreg allmd  split10pc spil 		$simple                                             ,  cluster(wbcode  cluster)
est store alllp1

xi: cgmreg allmd  split10pc spil 		$simple                   i.wbcode					,  cluster(wbcode  cluster)
est store alllp2

xi: cgmreg allmd split10pc spil 		$simple         $location i.wbcode					,  cluster(wbcode  cluster)
est store alllp3

xi: cgmreg allmd split10pc spil 		$simple  $rich1 $location i.wbcode					,  cluster(wbcode  cluster)
est store alllp4

xi: cgmreg allmd split10pc spil 		$simple  $rich1 $location i.wbcode if allm<top_allm	,  cluster(wbcode  cluster)
est store alllp5

xi: cgmreg allmd split10pc spil 		$simple  $rich1 $location i.wbcode if capital==0	,  cluster(wbcode  cluster)
est store alllp6

** 
xi: cgmreg allmd  split10pc spil 		$simple                             if borderdist1<median_bd  & no==0				,  cluster(wbcode  cluster)
est store alllp1c

xi: cgmreg allmd  split10pc spil 		$simple                    i.wbcode if borderdist1<median_bd  & no==0				,  cluster(wbcode  cluster)
est store alllp2c

xi: cgmreg allmd split10pc spil 		$simple         $location i.wbcode if borderdist1<median_bd  & no==0				,  cluster(wbcode  cluster)
est store alllp3c

xi: cgmreg allmd split10pc spil 		$simple  $rich1 $location i.wbcode if borderdist1<median_bd  & no==0				,  cluster(wbcode  cluster)
est store alllp4c

xi: cgmreg allmd split10pc spil 		$simple  $rich1 $location i.wbcode if allm<top_allm & borderdist1<median_bd  & no==0,  cluster(wbcode  cluster)
est store alllp5c

xi: cgmreg allmd split10pc spil 		$simple  $rich1 $location i.wbcode if capital==0 & borderdist1<median_bd  & no==0,  cluster(wbcode  cluster)
est store alllp6c



*** All Main Events (excluding Riots and Protests and Non-Violent Events); Not Reported
******************************************************************************************************************************************************************
xi: cgmreg allmmd  split10pc 	spil 		$simple                                             		,  cluster(wbcode  cluster)
est store allllp1

xi: cgmreg allmmd	 split10pc 	spil 		$simple                   i.wbcode							,  cluster(wbcode  cluster)
est store allllp2

xi: cgmreg allmmd split10pc 	spil 		$simple         $location i.wbcode							,  cluster(wbcode  cluster)
est store allllp3

xi: cgmreg allmmd split10pc 	spil 		$simple  $rich1 $location i.wbcode							,  cluster(wbcode  cluster)
est store allllp4

xi: cgmreg allmmd split10pc 	spil 		$simple  $rich1 $location i.wbcode if allmm<top_allmm		,  cluster(wbcode  cluster)
est store allllp5

xi: cgmreg allmmd split10pc 	spil 		$simple  $rich1 $location i.wbcode if capital==0			,  cluster(wbcode  cluster)
est store allllp6

** close to the border 
xi: cgmreg allmmd  split10pc 	spil 		$simple                             if borderdist1<median_bd  & no==0				,  cluster(wbcode  cluster)
est store allllp1c

xi: cgmreg allmmd  split10pc 	spil 		$simple                    i.wbcode if borderdist1<median_bd  & no==0				,  cluster(wbcode  cluster)
est store allllp2c

xi: cgmreg allmmd split10pc 	spil 		$simple         $location i.wbcode if borderdist1<median_bd  & no==0				,  cluster(wbcode  cluster)
est store allllp3c

xi: cgmreg allmd split10pc 		spil 		$simple  $rich1 $location i.wbcode if borderdist1<median_bd  & no==0				,  cluster(wbcode  cluster)
est store allllp4c

xi: cgmreg allmmd split10pc 	spil 		$simple  $rich1 $location i.wbcode if allmm<top_allmm & borderdist1<median_bd  & no==0,  cluster(wbcode  cluster)
est store allllp5c

xi: cgmreg allmmd split10pc 	spil 		$simple  $rich1 $location i.wbcode if capital==0 & borderdist1<median_bd  & no==0,  cluster(wbcode  cluster)
est store allllp6c




*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
*** Table 2. Baseline Country Fixed-Effects Estimates (ACLED).
*** Panel B. Linear Probability Model (LPM) Estimates with country Fixed-Effects
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************

** All events (reported in Panel B-Table 2)
*****************************************************************************************
esttab allp1 allp2 allp3 allp4   allp5 allp6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using o.Table_2Ba.tex

esttab allp1c allp2c allp3c allp4c   allp5c allp6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using o.Table_2Bb.tex
   
	   
** All Main Events (no riots and potests); Not-Reported
***************************************************************************************************************************************************************************	   
estout alllp1 alllp2 alllp3 alllp4   alllp5 alllp6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)

estout alllp1c alllp2c alllp3c alllp4c   alllp5c alllp6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)


** Alternative All Main Events; no riots no protests no non-violent events; Not-Reported
***************************************************************************************************************************************************************************
estout allllp1 allllp2 allllp3 allllp4   allllp5 allllp6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)

estout allllp1c allllp2c allllp3c allllp4c   allllp5c allllp6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
   



	   
	   
	   
	   
	   
	   
	   
