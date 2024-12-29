

** Table 2-Panel A
***********************************************************************************************************************************************************************
***********************************************************************************************************************************************************************
** This .do file runs all Negative Binomial (ML) models with the ACLED adta for the Tables in the main part of the paper.
** The NB-ML specifications are reported in Table 2. Panel A. 
************************************************************************************************************************************************************************
************************************************************************************************************************************************************************


** Preliminaries
*****************
************************************************************************************************************************************************************************
************************************************************************************************************************************************************************

* Notes:
********
** (1): To get double-clustered s.e. one needs to run the program three times, changing the cluster(); 
** (a) cluster (ethnic family); (b) wbcode (country); (c) inter (intersection of ethnic family and country)
************************************************************************************************************************************************************************




** Conditioning Sets
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************

global regi 			region_n region_s region_w region_e 

global simple			lnpop60 lnkm2split  lakedum riverdum
global location 		capital borderdist1 capdistance1 seadist1 coastal 
global geo	 			mean_elev mean_suit diamondd malariasuit petroleum island city1400 
global rich1 			mean_elev mean_suit diamondd malariasuit petroleum island city1400 


** Estimate Baseline Regressions. Dependent Variable. Number of All Events/Incidents
*************************************************************************************************************************************************************************
xi: nbreg all  	split10pc spil 		$simple                     					,  robust cluster(  cluster)
est store alnb1

xi: nbreg all  	split10pc spil 		$simple                  i.wbcode				,  robust cluster(  cluster)
est store alnb2

xi: nbreg all 	split10pc spil 		$simple         $location i.wbcode				,  robust cluster(  cluster)
est store alnb3

xi: nbreg all 	split10pc spil 		$simple  $rich1 $location i.wbcode				,  robust cluster(  cluster)
est store alnb4

xi: nbreg all 	split10pc spil		$simple  $rich1 $location i.wbcode if all<top_all,  robust cluster(  cluster)
est store alnb5

xi: nbreg all 	split10pc spil 		$simple  $rich1 $location i.wbcode if capital==0,  robust cluster(  cluster)
est store alnb6

**
xi: nbreg all  	split10pc spil 		$simple                           if borderdist1<median_bd  & no==0					,  robust cluster(  cluster)
est store alnb1c

xi: nbreg all  	split10pc spil 		$simple                   i.wbcode if borderdist1<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb2c

xi: nbreg all 	split10pc spil 		$simple         $location i.wbcode if borderdist1<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb3c

xi: nbreg all 	split10pc spil 		$simple  $rich1 $location i.wbcode if borderdist1<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb4c

xi: nbreg all 	split10pc spil 		$simple  $rich1 $location i.wbcode if all<top_all & borderdist1<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb5c

xi: nbreg all 	split10pc spil 		$simple  $rich1 $location i.wbcode if capital==0 & borderdist1<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb6c


** Estimate Baseline Regressions. Dependent Variable. Number of All Events/Incidents, exclduing Riots and Protests (not reported)
*************************************************************************************************************************************************************************
xi: nbreg allm  split10pc spil 		$simple                                             ,  robust cluster(  cluster)
est store allnb1

xi: nbreg allm  split10pc spil 		$simple                   i.wbcode					,  robust cluster(  cluster)
est store allnb2

xi: nbreg allm split10pc spil 		$simple         $location i.wbcode					,  robust cluster(  cluster)
est store allnb3

xi: nbreg allm split10pc spil 		$simple  $rich1 $location i.wbcode					,  robust cluster(  cluster)
est store allnb4

xi: nbreg allm split10pc spil 		$simple  $rich1 $location i.wbcode if allm<top_allm	,  robust cluster(  cluster)
est store allnb5

xi: nbreg allm split10pc spil 		$simple  $rich1 $location i.wbcode if capital==0	,  robust cluster(  cluster)
est store allnb6

xi: nbreg allm  split10pc spil 		$simple                             if borderdist1<median_bd  & no==0				,  robust cluster(  cluster)
est store allnb1c

xi: nbreg allm  split10pc spil 		$simple                    i.wbcode if borderdist1<median_bd  & no==0				,  robust cluster(  cluster)
est store allnb2c

xi: nbreg allm split10pc spil 		$simple         $location i.wbcode if borderdist1<median_bd  & no==0				,  robust cluster(  cluster)
est store allnb3c

xi: nbreg allm split10pc spil 		$simple  $rich1 $location i.wbcode if borderdist1<median_bd  & no==0				,  robust cluster(  cluster)
est store allnb4c

xi: nbreg allm split10pc spil 		$simple  $rich1 $location i.wbcode if allm<top_allm & borderdist1<median_bd  & no==0,  robust cluster(  cluster)
est store allnb5c

xi: nbreg allm split10pc spil 		$simple  $rich1 $location i.wbcode if capital==0 & borderdist1<median_bd  & no==0,  robust cluster(  cluster)
est store allnb6c



** Estimate Baseline Regressions. Dependent Variable. Number of All Events/Incidents, exclduing Riots and Protests and Non-Violent Events (not reported)
*************************************************************************************************************************************************************************
xi: nbreg allmm  split10pc 	spil 		$simple                                             		,  robust cluster(  cluster)
est store alllnb1

xi: nbreg allmm	 split10pc 	spil 		$simple                   i.wbcode							,  robust cluster(  cluster)
est store alllnb2

xi: nbreg allmm split10pc 	spil 		$simple         $location i.wbcode							,  robust cluster(  cluster)
est store alllnb3

xi: nbreg allmm split10pc 	spil 		$simple  $rich1 $location i.wbcode							,  robust cluster(  cluster)
est store alllnb4

xi: nbreg allmm split10pc 	spil 		$simple  $rich1 $location i.wbcode if allmm<top_allmm		,  robust cluster(  cluster)
est store alllnb5

xi: nbreg allmm split10pc 	spil 		$simple  $rich1 $location i.wbcode if capital==0			,  robust cluster(  cluster)
est store alllnb6

xi: nbreg allmm  split10pc 	spil 		$simple                             if borderdist1<median_bd  & no==0				,  robust cluster(  cluster)
est store alllnb1c

xi: nbreg allmm  split10pc 	spil 		$simple                    i.wbcode if borderdist1<median_bd  & no==0				,  robust cluster(  cluster)
est store alllnb2c

xi: nbreg allmm split10pc 	spil 		$simple         $location i.wbcode if borderdist1<median_bd  & no==0				,  robust cluster(  cluster)
est store alllnb3c

xi: nbreg allm split10pc 	spil 		$simple  $rich1 $location i.wbcode if borderdist1<median_bd  & no==0				,  robust cluster(  cluster)
est store alllnb4c

xi: nbreg allmm split10pc 	spil 		$simple  $rich1 $location i.wbcode if allmm<top_allmm & borderdist1<median_bd  & no==0,  robust cluster(  cluster)
est store alllnb5c

xi: nbreg allmm split10pc 	spil 		$simple  $rich1 $location i.wbcode if capital==0 & borderdist1<median_bd  & no==0,  robust cluster(  cluster)
est store alllnb6c




*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************
*** Table 2. Baseline Country Fixed-Effects Estimates (ACLED).
*** Panel A. Negative Binomial ML Estimates with country Fixed-Effects
*************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************

** All events; all ethnic homelands; columns (1)-(6)
*************************************************************************************************************************************************************************
esttab alnb1 alnb2 alnb3  alnb4 alnb5 alnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01)  ///
	   style(tex) replace, using o.Table_2Aa.tex


** All events; ethnic homelands close to the border. columns (7)-(12)
*************************************************************************************************************************************************************************	   
esttab alnb1c alnb2c alnb3c  alnb4c alnb5c alnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01)  ///
	   style(tex) replace, using o.Table_2Ab.tex
   
	   
** All Main Events (no riots and potests); Not Reported
**************************************************************************************************************************************************************************	   
estout allnb1 allnb2 allnb3   allnb4 allnb5 allnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)

estout allnb1c allnb2c allnb3c   allnb4c allnb5c allnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)


** Alternative All Main Events; no riots no protests and no non-violent events; Not Reported.
***************************************************************************************************************************************************************************
estout alllnb1 alllnb2 alllnb3   alllnb4 alllnb5 alllnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)

estout alllnb1c alllnb2c alllnb3c   alllnb4c alllnb5c alllnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
   




