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




******************************************************************************************************************************************8
clear all
use homelands825.dta



** Preliminaries
****************************************************************************************************************************************************************************************
****************************************************************************************************************************************************************************************
describe all
d split10pc lakedum riverdum lnkm2group mean_elev  mean_suit malaria sead  diamond petroleum  share precondummy distcon lndistcon slave_dummy lnslexports1  empire distemp lndistemp city1400 

global allvars 	pop60_new km2group lakedum riverdum  mean_elev mean_suit malaria sead   diamond petroleum ///
				precondummy distcon  slave_dummy exports /// 
				empire distemp city1400 nmbr_cluster share

				
** Appendix Table 1. Summary Statistics at the Ethnic Homeland Level
***************************************************************************************************************************************************************************************
***************************************************************************************************************************************************************************************

** Panel A: All Ethnic Homelands (825 obs)
*****************************************************************************************
tabstat $allvars  							, stats(n mean sd    p50  min max) col(stats)

** Panel B: Ethnic Homelands close to the National Border (413 obs)
*****************************************************************************************
tabstat $allvars  if  borddist<=median_bd 	, stats(n mean sd    p50  min max) col(stats)




***************************************************************************************************************************************************************************************
*** Table 1 Border (Ethnic Partitioning) Artificiality
***************************************************************************************************************************************************************************************
***************************************************************************************************************************************************************************************
***************************************************************************************************************************************************************************************

************ Testing ***********

// Adding number of fatalities Variable

use z.final_homelands.dta
collapse (sum) numbr_fatalies=nbr_fatalies, by(name)

save z.nbr_fatalies_per_homelands.dta, replace
clear all

use homelands825.dta
mer 1:1 name using z.nbr_fatalies_per_homelands.dta, nogen
order numbr_fatalies, after(name)

save homelands825.dta, replace



// Tests   - Hassane

**Number of fatalities
xi: cgmreg 	numbr_fatalies split10pc  	lakedum riverdum diamond petroleum lnkm2group   			region_s region_c region_e region_w ,  robust cluster(wbcode cluster)
est store test0

**Number of battles
xi: cgmreg 	battles  split10pc  	lakedum riverdum diamond petroleum lnkm2group   			region_s region_c region_e region_w ,  robust cluster(wbcode cluster)
est store test1

**Number of riots 
xi: cgmreg 	riots split10pc  	lakedum riverdum diamond petroleum lnkm2group   			region_s region_c region_e region_w ,  robust cluster(wbcode cluster)
est store test2

**Number of events related to vioence against civilians 
xi: cgmreg 	vio split10pc  	lakedum riverdum diamond petroleum lnkm2group   			region_s region_c region_e region_w ,  robust cluster(wbcode cluster)
est store test3

esttab test0 test1 test2 test3, cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_p r2_a N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc 	lakedum riverdum diamond petroleum lnkm2group) starlevels(* 0.1 ** 0.05  *** 0.01) style(tex) replace, using 0.Table_battles.tex 




** Table 1 - Panel A: Panel A: Geography, Ecology, Natural Resources and Ethnic Partitioning
********************************************************************************************
***************************************************************************************************************************************************************************************

**Size (log land area)
xi: cgmreg 	split10pc  					 lnkm2group   			region_s region_c region_e region_w ,  robust cluster(wbcode cluster)
est store sp0

**Size and water (lake and river dummies)
xi: cgmreg 	split10pc  	lakedum riverdum lnkm2group   			region_s region_c region_e region_w ,  robust cluster(wbcode cluster)
est store sp1

*Size and water and land quality and terrain features
xi: cgmreg split10pc   	lakedum riverdum lnkm2group   mean_elev  mean_suit  region_s region_c region_e region_w ,  robust cluster(wbcode cluster)
est store sp2

**Size and water and ecology (malaria and distance to the coast)
xi: cgmreg split10pc   	lakedum riverdum lnkm2group   	malaria sead region_s region_c region_e region_w ,  robust cluster(wbcode cluster)
est store sp3

**Size and water and natural resources (diamond mine and oil indicators)
xi: cgmreg split10pc   	lakedum riverdum lnkm2group diamond petroleum region_s region_c region_e region_w ,  robust cluster(wbcode cluster)
est store sp4

**Size and water and nearby group's features
xi: cgmreg split10pc   	lakedum riverdum lnkm2group share region_s region_c region_e region_w ,  robust cluster(wbcode cluster)
est store sp5

**all geographical features 
xi: cgmreg split10pc   	lakedum riverdum lnkm2group mean_elev  mean_suit malaria sead  diamond petroleum  share region_s region_c region_e region_w ,  robust cluster(wbcode cluster)
est store sp6


************ Testing ***********
* Table 1 - Panel A: 	Geography, Ecology, Natural Resources and Ethnic Partitioning
**************************************************************************************************************************************************
esttab sp0 sp1  sp2  sp3  sp4  sp5 sp6  , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_p r2_a N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(lnkm2group lakedum riverdum  mean_elev mean_suit malaria sead   diamond petroleum share_same ) starlevels(* 0.1 ** 0.05  *** 0.01) replace, using 0.Table_1A.tex
************ Testing ***********
	   
	   
	   
** Table 1 - Panel B: Historical (Pre-colonial) Features and Ethnic Partitioning
***************************************************************************************************************************************************************************************
***************************************************************************************************************************************************************************************
	   
** Pre-colonial Conflict dummy
xi: cgmreg	 split10pc 			lakedum riverdum  lnkm2group  		precondummy 	region_s region_c region_e region_w,  robust cluster(cluster wbcode)
est store mspa1

** Distance to Pre-colonial Conflict 
xi: cgmreg	 split10pc 			lakedum riverdum  lnkm2group   		distcon			region_s region_c region_e region_w,  robust cluster(cluster wbcode)
est store mspa2

** Log Distance to Pre-colonial Conflict (not reported in the tables)
xi: cgmreg split10pc 			lakedum riverdum  lnkm2group   		lndistcon		region_s region_c region_e region_w,  robust cluster(cluster wbcode)
est store mspa2a

** Slave Trades Dummy	
xi: cgmreg split10pc    		lakedum riverdum  lnkm2group   		slave_dummy  	region_s region_c region_e region_w,  robust cluster(cluster wbcode )
est store mspa3

** Log of slave (normalization follows Nunn (2008)
xi: cgmreg split10pc    		lakedum riverdum  lnkm2group   		lnslexports1  	region_s region_c region_e region_w,  robust cluster(cluster wbcode)
est store mspa4
	  
** Empire (Large Kingdom) Dummy
xi: cgmreg split10pc       		empire  			lakedum riverdum lnkm2group  region_s region_c region_e region_w	,  robust cluster(cluster wbcode )
est store mspa5

** Distance to empire (large kingdom)
xi: cgmreg split10pc       		distemp  			lakedum riverdum lnkm2group  region_s region_c region_e region_w	,  robust cluster(cluster wbcode)
est store mspa6

** Log distnace to empire (large kingdom). [not reported in the tables] 
xi: cgmreg split10pc       		lndistemp  			lakedum riverdum lnkm2group  region_s region_c region_e region_w	,  robust cluster(cluster wbcode)
est store mspa6a

** Major city in 1400 dummy
xi: cgmreg split10pc       		city1400  			lakedum riverdum lnkm2group  region_s region_c region_e region_w	,  robust cluster(cluster wbcode)
est store mspa7

	 



**************************************************************************************************************************************************
**************************************************************************************************************************************************
** Table 1: Border (Ethnic Partitioning) Artificiality 
**************************************************************************************************************************************************
**************************************************************************************************************************************************

** Table 1 - Panel A: 	Geography, Ecology, Natural Resources and Ethnic Partitioning
**************************************************************************************************************************************************
estout sp0 sp1  sp2  sp3  sp4  sp5 sp6  , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_p r2_a N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(lnkm2group lakedum riverdum  mean_elev mean_suit malaria sead   diamond petroleum share_same ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
	 
**************************************************************************************************************************************************

** Table 1 - Panel B: 	Historical (Pre-colonial) Features and Ethnic Partitioning
**************************************************************************************************************************************************
estout mspa1 mspa2 mspa2a mspa3 mspa4 mspa5 mspa6 mspa6a mspa7   , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_p r2_a N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(lnkm2group 	lakedum riverdum  precondummy distcon lndistcon slave_dummy lnslexports1  empire distemp lndistemp city1400) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)
  
	     

	
	
	
	

***************************************************************************************************************************************************************************************
*** Appendix Table 8. Border (Ethnic Partitioning) Artificiality
*** Pre-colonial Ethnic Features (using data from Murdock (1967)) and Ethnic Partitioning
***************************************************************************************************************************************************************************************
***************************************************************************************************************************************************************************************
***************************************************************************************************************************************************************************************

** Part A. Generate the variables using Murdock (1967)
*******************************************************
*******************************************************
tab v1
gen gathering=0 if v1!=.
replace gathering=1 if v1>0 & v1!=.
label var gathering "indicator that equals zero if gathering is 0%-5% and 1 if higher (6%-85%)."

tab v2
gen hunting=0 if v2!=.
replace hunting=1 if v2>0 & v2!=.
label var hunting "indicator that equals zero if hunting is 0%-5% and 1 if higher(6%-65%)."

tab v3
gen fishing=0 if v3!=.
replace fishin=1 if v3>0 & v3!=.
label var fishing "indicator that equals zero if fishing is 0%-5% and 1 if higher(6%-85%)."

tab v4
gen anhusb=v4 if v4!=.
label var anhusb "Animal Husbandry variable (0-9 scale)."
**we do not distinguish between type of animal husbandry (pigs, sheep, etc) as described in v40

tab v41
gen milking=0 if v41!=.
replace milking=. if v41==0
replace milking=1 if v41==2
label var milking "indicator on whether domestic animals are milked more often than sporadically."

tab v5
gen agricdep=v5 if v5!=.
label var agricdep "Dependence on agriculture variable (0-9 scale)."

*v28 is also reflecting the intensity of agriculture 
tab v28
gen agricdepalt=0 if v28!=.
replace agricdepalt=. if v28==0
replace agricdepalt=0 if v28==1
replace agricdepalt=1 if v28==2
replace agricdepalt=2 if v28==3
replace agricdepalt=3 if v28==5
replace agricdepalt=4 if v28==6
label var agricdepalt "alternative index of dependence on agriculture (0-4)."


**v42 also reflects intensity on agriculture in binary setting but there is no variation 
tab v8
gen polygyny=0 if v8!=.
replace polygyny=. if v8==0
replace polygyny=1 if v8==2 | v8==4 | v8==5
label var polygyny "indicator that equals one if polygyny is present and zero if not."


tab v9
gen polygynyalt=0 if v9!=.
replace polygynyalt=1 if v9==2
label var polygynyal "alternative indicator for polygyny (as in Fenske)."


tab v15
gen clans=0 if v15!=.
replace clans=1 if v15==6 & v15!=.
replace clans=. if v15==0
label var clans "indicator for clan communities (commuity marriage organization)."


tab v16
gen clansalt=0 if v16!=.
replace clansalt=1 if v16==1 
replace clansalt=1 if v16==2 
replace clansalt=. if v16==0 
label var clansalt "alternative indicator for clan communities (commuity marriage organization)."


gen compset=0 if v30!=.
replace compset=. if v30==0
replace compset=1 if v30==7
replace compset=1 if v30==8
label var compset "indicator for compact and complex settlements. (zeros indicate nomadic/sedentary)."


tab v32
gen locjuris=0 if v32!=.
replace locjuris=. if v32==0
replace locjuris=v32-2 if v32!=. & v32!=0
label var locjuris "jurisdictional hierarchy at the local level; equals 2, 3, or 4"


tab v43
gen pater=0 if v43!=.
replace pater=. if v43==0
replace pater=1 if v43==1
label var pater "dummy that equals one if there are patrilineal descent types."


** not enoought data on the next set of variables that reflect sex differences in leather, pottery, baot building, hunting, fishing
** not enoought data on the next set of variables that reflect age of occupational specialization in leather, weaving, etc

tab v66
gen class=v66-1
replace class=. if v66==0
label var class "class startification index (0-5 range)."

gen classdummy=class
replace classdummy=1 if class==1 | class==2 | class==3 | class==4 
label var classdummy "indicator for stratified societies (zero=egalitarian). as in Gennaioli-Rainer (2007)."

tab v72
gen elections=0 if v72!=.
replace elections=. if v72==0
replace elections=1 if v72==6
label var elections "indicator on whether there are elections for the local headman."

tab v70
gen slavery=0 if v70!=.
replace slavery=. if v70==0
replace slavery=1 if v70>1 & v70!=.
label var slavery "indicator for presence of slavery. as in Fenske."

tab v74
gen property=0 if v74!=.
replace property=. if v74==0
replace property=1 if v74>1 & v74!=.
label var property "indictaor for presence of some form or property rights. as in Fenske."





** Part B: Run the Linear Probability Models
*********************************************************************************************************
*********************************************************************************************************
** Complex Settlements
xi: cgmreg split10pc 		compset 			lakedum riverdum lnkm2group region_s region_c region_e region_w,  robust cluster(wbcode cluster)
est store mspi1

** Pre-colonial share of agricultural production (0-9 scale)
xi: cgmreg split10pc 		agrshare  			lakedum riverdum lnkm2group region_s region_c region_e region_w,  robust cluster( wbcode cluster)
est store mspi2

** Proxy for Pastoralness (dependence on animal husbandry; v4 0-9 scale)
xi: cgmreg split10pc 		anhus   			lakedum riverdum lnkm2group region_s region_c region_e region_w,  robust cluster( wbcode cluster)
est store mspi3

** Local Elections
xi: cgmreg split10pc 		elections 			lakedum riverdum lnkm2group region_s region_c region_e region_w,  robust cluster(wbcode cluster)
est store mspi4

*Inheritance Rule for Property 
xi: cgmreg split10pc 		property 			lakedum riverdum lnkm2group region_s region_c region_e region_w,  robust cluster(wbcode cluster)
est store mspi5

*Pre-colonial ethnic political centralization (binary as in Gennaioli and Rainer (2007))
xi: cgmreg split10pc 		gr 					lakedum riverdum lnkm2group region_s region_c region_e region_w,  robust cluster(wbcode cluster)
est store mspi6

*Pre-colonial ethnic class stratification (binary as in Gennaioli and Rainer (2007))
xi: cgmreg split10pc 		classdummy 			lakedum riverdum lnkm2group region_s region_c region_e region_w ,  robust cluster( wbcode cluster)
est store mspi7

*Pre-colonial share of polygyny
xi: cgmreg split10pc 		polygyny  			lakedum riverdum lnkm2group region_s region_c region_e region_w,  robust cluster( wbcode cluster)
est store mspi8
******************************************************************************************************************************************************

***************************************************************************************************************************************************************************************
*** Appendix Table 8. Border (Ethnic Partitioning) Artificiality
*** Pre-colonial Ethnic Features (using data from Murdock (1967)) and Ethnic Partitioning
***************************************************************************************************************************************************************************************
estout mspi1 mspi2 mspi3 mspi4 mspi5 mspi6 mspi7 mspi8  , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a r2_a N , fmt(%9.3f %9.0g) labels(Log Likelihood)) /// 
	   keep(lnkm2group lakedum riverdum  compset elections property gr classdummy  agrshare anhusb polygyny ) starlevels(* 0.1 ** 0.05  *** 0.01) style(fixed)


	
	
	
	
	
	
	
	
	
	
	
	
	
	
	