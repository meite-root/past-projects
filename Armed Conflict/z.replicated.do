*****************
* Initializing *
****************

clear all
capture log close
cd "C:\Users\Hassane\Desktop\School Files -  Spring 2020\Final Capstone Project\complete dataset\Stelios_replica"
set more off
 


****************
*   Cleaning   *
****************

import delimited "z.ArcGIS_imported\homelands_arcGIS.txt"

save z.homelands_arcGIS.dta, replace

// I - Unnecessary variables

drop fid_1 fid_1_1 fid_1_1_1 fid_1_1__1 fid_2 count_ 
drop name_displ code 
drop name_30-codetype
drop v8tr-v82tr 
drop featurecla-type 
drop geou_dif-mapcolor13 
drop wikipedia-region_un 
drop region_wb-name_zh 
 

// II - Unnecessary Observations
drop if missing(culturegrp) // removes the observations with odd fid strings
// drop if subregion == "Seven seas (open ocean)"
// drop if subregion == "Western Europe"
// drop if subregion == "Southern Europe"


	
	
	


// III - renaming to match the original 
rename count_1 riverscount
rename count_2 waterbodiescount
rename count_3 petrolieumcount
rename count_4 diamondcount
rename admin country
rename name ethn_name

// IV - Creating new variables

*0. Setup 

destring fid, replace
*1. perc_ethn_span - percentage of total original homeland area spanned by the split subgroup
gen perc_ethn_span = (indiv_area/area_geome)*100
order perc_ethn_span, before(area_geome)

*2. nbr_subgrps - Number of split subgroups per ethnic group.
save z.homelands_arcGIS_clean.dta, replace
contract ethn_name , freq(nbr_subgrps)
mer 1:m ethn_name using z.homelands_arcGIS_clean.dta, nogen
order nbr_subgrps, before(area_geome)

*3. split10pc - Dummy variables for subgroups belonging to an homeland that has had at least 10% of its territory partitioned.

generate split10pc = ( abs(50-perc_ethn_span)<40 ) if !missing(perc_ethn_span) 
*--> 1 if the ethnic subgroup represents more than 10% or less than 90% of the total homaland

save z.homelands_arcGIS_clean.dta, replace
collapse (mean) spec_cases10pc=split10pc, by(ethn_name) // average of split10pc dummy.
mer 1:m ethn_name using z.homelands_arcGIS_clean.dta, nogen
order spec_cases10pc, before(area_geome)
*--> Variable spec_cases10pc will indicate whether an ethnic subgroup has been mistakenly classified or not, in the case it is neither 1 nor 0

replace split10pc = 1 if spec_cases10pc!=0 & spec_cases10pc!=1
*--> replacing split10pc by 1 for mistakenly classified ethnic subgroups (at least onen of)
order split10pc, before(area_geome)


*4. split5pc - Dummy variables for subgroups belonging to an homeland that has had at least 5% of its territory partitioned.

generate split5pc = ( abs(50-perc_ethn_span)<45 ) if !missing(perc_ethn_span) 
*--> 1 if the ethnic subgroup represents more than 5% or less than 95% of the total homaland

save z.homelands_arcGIS_clean.dta, replace
collapse (mean) spec_cases5pc=split5pc, by(ethn_name) // average of split5pc dummy.
mer 1:m ethn_name using z.homelands_arcGIS_clean.dta, nogen
order spec_cases5pc, before(area_geome)
*--> Variable spec_cases5pc will indicate whether an ethnic subgroup has been mistakenly classified or not, in the case it is neither 1 nor 0

replace split5pc = 1 if spec_cases5pc!=0 & spec_cases5pc!=1
*--> replacing split5pc by 1 for mistakenly classified ethnic subgroups (at least onen of)
order split5pc, before(area_geome)

*5. riverdum - Dummy variable indicating the presence of a river in ethnic subgroup subgroup
generate riverdum = ( riverscount !=0 ) if !missing(riverscount)
order riverscount riverdum, before(area_geome)

*6. lakedum - Dummy variable indicating the presence of a waterbodies (lakes, lagoons, reservoirs) in ethnic subgroup
generate lakedum = ( waterbodiescount !=0 ) if !missing(waterbodiescount)
order waterbodiescount lakedum, before(area_geome)



*7. km2group - area spanned by the ethnic subgroup in 1000's of km
gen km2group = indiv_area/1000
gen lnkm2group = ln(km2group)
order km2group lnkm2group, before(area_geome)

*8. ccode - endoded coutry variable
encode adm0_a3, gen(ccode)
xtset ccode


*9. Dummies for regions of Africa
tabulate subregion, generate(region_)

rename region_1 region_e
rename region_2 region_m    
rename region_3 region_n    
rename region_4 region_s
rename region_5 region_w
//
save z.homelands_arcGIS_clean.dta, replace
clear all

*10. sead - Variable indicating distance to the coast
import delimited "z.ArcGIS_imported\homelands_arcGIS_dist_to_coast.txt"
drop rowid_ objectid near_fid 
rename in_fid fid 
merge m:1 fid using z.homelands_arcGIS_clean.dta, nogen
rename near_dist sead
//
save z.homelands_arcGIS_clean.dta, replace
clear all


*11. mean_elev - Average elevation of ethnic subgroup
import delimited "z.ArcGIS_imported\homelands_arcGIS_elevation_by_homeland.csv"
drop rowid_ count-range std-median 
rename fid_1 fid 
merge m:1 fid using z.homelands_arcGIS_clean.dta, nogen
rename mean mean_elev
//
save z.homelands_arcGIS_clean.dta, replace
clear all

*12. malaria - Average elevation of ethnic subgroup
import delimited "z.ArcGIS_imported\homelands_arcGIS_malaria_by_homeland.csv"
drop rowid_ count-range std-sum 
rename fid_1 fid 
merge m:1 fid using z.homelands_arcGIS_clean.dta, nogen
rename mean malaria
//
save z.homelands_arcGIS_clean.dta, replace

*13. petroleum - Dummy variable indicating the presence petroleum fields
generate petroleum = ( petrolieumcount !=0 ) if !missing(petrolieumcount)
order petrolieumcount petrolieum, before(area_geome)
//
save z.homelands_arcGIS_clean.dta, replace


*14. diamond - Dummy variable indicating the presence Natural resources mines
generate diamond = ( diamondcount !=0 ) if !missing(diamondcount)
order diamondcount diamond, before(area_geome)
//
save z.homelands_arcGIS_clean.dta, replace


*15. mean_suit - Dummy variable indicating the suitability of the land for agriculture !!!!!!!!!!!!!! Imported from original

rename ethn_name name
merge m:1 name using homelands825, nogen  keepusing(mean_suit)
order mean_suit , before(area_geome)
rename name ethn_name
save z.homelands_arcGIS_clean.dta, replace


*16. share_same - Indicator of the proportion of nearby groups of the same cluster !!!!!!!!!!!!!! Imported from original

rename ethn_name name
merge m:1 name using homelands825, nogen  keepusing(share_same)
order share_same , before(area_geome)
rename name ethn_name
save z.homelands_arcGIS_clean.dta, replace


*17. island - indicates whether the split homeland is an island or not.  !!!!!!!!!!!!!! Imported from original

rename ethn_name name
merge m:1 name using homelands825, nogen  keepusing(island)
rename name ethn_name
save z.homelands_arcGIS_clean.dta, replace
 
 
*18. Atlas name !!!!!!!!!!!!!! Imported from original

rename ethn_name name
merge m:1 name using homelands825, nogen  keepusing(atlasname)
rename name ethn_name
save z.homelands_arcGIS_clean.dta, replace
clear all


*19. pop2010 - Population Country-Ethnicity Homeland in 2010
import delimited "z.ArcGIS_imported\homelands_arcGIS_population_by_homeland.csv"
drop rowid_ count - std
rename fid_1 fid 
merge m:1 fid using z.homelands_arcGIS_clean.dta, nogen
rename sum pop2010

*20. lnpop2010 - Log population Country-Ethnicity Homeland in 2010
gen lnpop2010 = ln(pop2010)
//
save z.homelands_arcGIS_clean.dta, replace


*21. capital - Indicator for country-ethnic homelands where capital cities fall.
rename count_5 capital
order capital, before(sead)
//
save z.homelands_arcGIS_clean.dta, replace
clear all


*22. capidist - Variable indicating distance to the nearest capital city
import delimited "z.ArcGIS_imported\homelands_arcGIS_dist_to_capital.txt"
drop rowid_ objectid near_fid 
rename in_fid fid 
merge m:1 fid using z.homelands_arcGIS_clean.dta, nogen
rename near_dist capidist
order capidist, before(capital)
//
save z.homelands_arcGIS_clean.dta, replace


*23. coastal - Indicator for country-ethnic homelands adjacent to the seacoast.
replace coastal = ( coastal == 0 ) if !missing(coastal)
order coastal, before(sead)
save z.homelands_arcGIS_clean.dta, replace
clear all


*24. borderdist - Variable indicating distance to the national border
import delimited "z.ArcGIS_imported\homelands_arcGIS_dist_to_national_borders.txt"
drop rowid_ objectid near_fid 
rename in_fid fid 
merge m:1 fid using z.homelands_arcGIS_clean.dta, nogen
rename near_dist borderdist
order borderdist, before(capital)
//
save z.homelands_arcGIS_clean.dta, replace

*25. median_bd - Median distance to the national border. based on borderdist
sum borderdist , detail
gen median_bd = r(p50)


// V - Sorting & ordering
sort ethn_name
order adm0_a3 ethn_name culturegrp country

*****Save*****
save z.homelands_arcGIS_clean.dta, replace
clear all







*********************************************************************
*   Making it similar to the original mainfile 'homelands825.dta'   *
*********************************************************************
use z.homelands_arcGIS_clean.dta

// Renaming variables
rename culturegrp cluster
rename ethn_name name  


//ordering variables
order cluster name adm0_a3 ccode subregion lat lon atlasname country island split10pc split5pc pop2010 lnpop2010 km2group lakedum riverdum mean_elev mean_suit malaria sead diamond petroleum 

//Sort
sort name

*****Save*****
save z.final_homelands.dta, replace
clear all



********************************
*     Adding colonial data     *
********************************
use z.final_homelands.dta
merge m:1 adm0_a3 using colonial_data.dta, nogen
order french_col british_col mixed_col violent_ind independence time_under_col, before(id)

//Sort
sort name

*****Save*****
save z.final_homelands.dta, replace
clear all


* The following won't be matched: adm0_a3 == "COM" | "CPV" | "MUS" | "SAH" | "SOL" | "STP" | "SYC"
* Because I haven't filed colonial data on those countries.
*COM	Comoros
*CPV	Capo Verde
*MUS	Mauritius
*SAH	Western Sahara
*SOL	Somaliland
*STP	Sao Tome
*SYC	seychelle



*******************************************
*   Adding conflict data                  *
*******************************************

 * 1. Adding Conflict using the table generated by ArcGIS and that  assigns each conflic event to the Geographical space it falls into

//Importing the relevant data on conflict events, each distinguished by its fid value
import delimited "z.ArcGIS_imported\conflict_events_nearIDs.txt" 
rename fid in_fid
save conflict_events_nearIDs.dta, replace
clear all

//Importing the relevant data on homelands (obtained through the cleaning process above), each distinguished by its fid value
use z.final_homelands.dta
rename fid near_fid
save z.final_homelands.dta, replace
clear all

// Final merging
import delimited "z.ArcGIS_imported\conflicts_by_homelands_nearIDs.txt"
merge m:1 near_fid using z.final_homelands.dta, nogen
merge m:1 in_fid using conflict_events_nearIDs.dta, nogen

// Create Dummy Variables for battles, riots, and events of violence
tabulate event_type, generate(conflict_)

rename conflict_1 battle
rename conflict_2 explosion_Remote_violence    
rename conflict_3 protest   
rename conflict_4 riot
rename conflict_5 strategic_development
rename conflict_6 violence_against_civilians


//Cleaning
drop rowid_ objectid near_dist in_fid 
rename near_fid fid // fid being the unique identifier of each split homeland
sort name

//saving
save z.final_conflicts_x_homelands.dta, replace
clear all


* 2. Add fatalities: number of fatalities per split homeland

use z.final_conflicts_x_homelands.dta 
collapse (sum) nbr_fatalies=fatalities, by(fid)
save z.nbr_fatalies_per_homelands.dta, replace
clear all

use z.final_homelands.dta, replace
rename near_fid fid 
mer 1:1 fid using z.nbr_fatalies_per_homelands.dta, nogen
order nbr_fatalies, after(country)
rename nbr_fatalies fatalities

save z.final_homelands.dta, replace
clear all

* 2.1. Add top_fatalities:  Top 1% of respective variable. All conflict events
sum fatalities , detail
gen top_fatalities = r(p99)
order top_fatalities, after(fatalities)
save z.final_homelands.dta, replace

* 3. Add battles: number of battles	 per split homeland

use z.final_conflicts_x_homelands.dta 
collapse (sum) battles=battle, by(fid)
save z.nbr_fatalies_per_homelands.dta, replace
clear all

use z.final_homelands.dta, replace
mer 1:1 fid using z.nbr_fatalies_per_homelands.dta, nogen
order battles, after(country)

save z.final_homelands.dta, replace
clear all

* 3. Add riots: number of Riots and Protests per split homeland

use z.final_conflicts_x_homelands.dta 
collapse (sum) riots1=riot (sum) protests=protest, by(fid)
gen riots = riots1 + protests
save z.nbr_fatalies_per_homelands.dta, replace
clear all

use z.final_homelands.dta, replace
mer 1:1 fid using z.nbr_fatalies_per_homelands.dta, nogen keepusing(riots)
order riots, after(country)

save z.final_homelands.dta, replace
clear all

* 4. Add vio: number of events related to violence against civilians per split homeland

use z.final_conflicts_x_homelands.dta 
collapse (sum) vio=violence_against_civilians, by(fid)
save z.nbr_fatalies_per_homelands.dta, replace
clear all

use z.final_homelands.dta, replace
mer 1:1 fid using z.nbr_fatalies_per_homelands.dta, nogen
order vio, after(country)

save z.final_homelands.dta, replace
clear all

* 5. Add all: All civil conflict events/incidents (of all types)
use z.final_homelands.dta, replace
gen all = battles + riots + vio
order all, after(country)

* 6. Add top_all:  Top 1% of respective variable. All conflict events
sum all , detail
gen top_all = r(p99)
order top_all, after(all)
save z.final_homelands.dta, replace

*7. Add alldum - Dummy variable for country-ethnic regions with any type of conflict.
generate alldum = ( all !=0 ) if !missing(all)
order alldum, after(all)

*8. Final cleaning and ordering 
use z.final_homelands.dta, replace
order fid adm0_a3 ccode 
drop lat lon centroid_x centroid_y fid_1_1__2 fid_1_1__3 tribe_code id perc_ethn_span nbr_subgrps spec_cases10pc spec_cases5pc pop_rank-gdp_year  
sort name

save z.final_homelands.dta, replace
clear all






********************
*     analysis     *
********************
use z.final_homelands.dta

run cgmreg.ado  // This routine allows getting double-clustered standard errors using the multiway clustering method of Cameron, Gelbach and Miller (2011)
set matsize 10000 // larger capacity; for estimators


*---------------------------------------------------------------------------------------------------------------------------------------------------------------


** Table 1 - Panel A: Geography, Ecology, Natural Resources and Ethnic Partitioning
********************************************************************************************
***************************************************************************************************************************************************************************************

**Size (log land area)
xi: cgmreg 	split10pc  					 lnkm2group   			region_s region_m region_e region_w ,  robust cluster(adm0_a3 cluster)
est store sp0

**Size and water (lake and river dummies)
xi: cgmreg 	split10pc  	lakedum riverdum lnkm2group   			region_s region_m region_e region_w ,  robust cluster(adm0_a3 cluster)
est store sp1

*Size and water and land quality and terrain features
xi: cgmreg split10pc   	lakedum riverdum lnkm2group   mean_elev  mean_suit  region_s region_m region_e region_w ,  robust cluster(adm0_a3 cluster)
est store sp2

**Size and water and ecology (malaria and distance to the coast)
xi: cgmreg split10pc   	lakedum riverdum lnkm2group   	malaria sead region_s region_m region_e region_w ,  robust cluster(adm0_a3 cluster)
est store sp3

**Size and water and natural resources (diamond mine and oil indicators)
xi: cgmreg split10pc   	lakedum riverdum lnkm2group diamond petroleum region_s region_m region_e region_w ,  robust cluster(adm0_a3 cluster)
est store sp4

**Size and water and nearby group's features
xi: cgmreg split10pc   	lakedum riverdum lnkm2group share region_s region_m region_e region_w ,  robust cluster(adm0_a3 cluster)
est store sp5

**all geographical features 
// xi: cgmreg split10pc   	lakedum riverdum lnkm2group mean_elev  mean_suit malaria sead  diamond petroleum  region_s region_m region_e region_w ,  robust cluster(adm0_a3 cluster)
xi: cgmreg split10pc   	lakedum riverdum lnkm2group mean_elev   malaria sead  diamond petroleum  region_s region_m region_e region_w ,  robust cluster(adm0_a3 cluster)
est store sp6


** Table 1 - Panel A: 	Geography, Ecology, Natural Resources and Ethnic Partitioning
**************************************************************************************************************************************************
	esttab sp0 sp1  sp2  sp3  sp4  sp5 sp6  , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
		   stats(r2_p r2_a N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(lnkm2group lakedum riverdum  mean_elev mean_suit malaria sead   diamond petroleum share_same ) starlevels(* 0.1 ** 0.05  *** 0.01) style(tex) replace, using Table_1A.tex 
		 
		
		
		
		
		
*---------------------------------------------------------------------------------------------------------------------------------------------------------------


** Table 2 - Ethnic Partitioning and Civil conflict
********************************************************************************************
***************************************************************************************************************************************************************************************

clear all
use z.final_homelands.dta
		   
*1 Conditioning Sets
xtset ccode  // Declare data to be panel (done in the orginial)


global regi 			region_s region_m region_e region_w 

global simple			lnpop2010 lnkm2group lakedum riverdum
global location 		capital borderdist capidist sead coastal 
global geo	 			mean_elev mean_suit diamond malaria petroleum island  // + city1400 - could not find it
global rich1	   		mean_elev mean_suit diamond malaria petroleum island // + city1400 - could not find it


*- Get spil - Share of adjacent split groups (10%) to total number of neighboring groups

clear all 
import delimited "z.ArcGIS_imported\homelands_adjacent.txt"
drop objectid length node_count 
*--> importing the polygon neighbours table

rename src_fid fid
merge m:1 fid using z.final_homelands.dta, nogen keepusing(name adm0_a3)
rename fid src_fid
rename name src_name
*--> identifying each polygon of focus

rename nbr_fid fid
merge m:1 fid using z.final_homelands.dta, nogen keepusing(name split10pc split5pc)
rename fid nbr_fid
rename name adjacents
rename src_fid fid
sort fid
*--> Identifying each neighbouring polygons

order fid adm0_a3 src_name adjacents split5pc split10pc 

save homelands_adjacent.dta, replace
collapse (mean) spil =split10pc, by(fid)
*--> Calculating the percentage of split groups


mer 1:m fid  using z.final_homelands.dta, nogen
order spil, after(sead)
*--> Adding to z.final_homelands.dta

save z.final_homelands.dta, replace


*- Get no - Identifier for country-ethnicity observations with no variation close to borders
rename adm0_a3 wbcode
mer m:1 name wbcode using aer_all2010.dta, nogen keepusing(no)
rename wbcode adm0_a3
drop if missing(fid)
replace no = 0 if missing(no)

	   
		   
		   
*2A- Estimate Baseline Regressions. Dependent Variable: Number of All Events/Incidents
*************************************************************************************************************************************************************************
*** Panel A - Negative Binomial ML Estimates with country Fixed-Effects
*************************************************************************************************************************************************************************


xi: nbreg all  	split10pc spil 		$simple                     					,  robust cluster(  cluster)
est store alnb1

xi: nbreg all  	split10pc spil 		$simple                  i.adm0_a3 				,  robust cluster(  cluster)
est store alnb2

xi: nbreg all 	split10pc spil 		$simple         $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb3

xi: nbreg all 	split10pc spil 		$simple  $rich1 $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb4

xi: nbreg all 	split10pc spil		$simple  $rich1 $location i.adm0_a3 if all<top_all,  robust cluster(  cluster)
est store alnb5

xi: nbreg all 	split10pc spil 		$simple  $rich1 $location i.adm0_a3 if capital==0,  robust cluster(  cluster)
est store alnb6

**
xi: nbreg all  	split10pc spil 		$simple                           if borderdist<median_bd  & no==0					,  robust cluster(  cluster)
est store alnb1c

xi: nbreg all  	split10pc spil 		$simple                   i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb2c

xi: nbreg all 	split10pc spil 		$simple         $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb3c

xi: nbreg all 	split10pc spil 		$simple  $rich1 $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb4c

xi: nbreg all 	split10pc spil 		$simple  $rich1 $location i.adm0_a3 if all<top_all & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb5c

xi: nbreg all 	split10pc spil 		$simple  $rich1 $location i.adm0_a3 if capital==0 & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb6c



*** Table 2. Baseline Country Fixed-Effects Estimates (ACLED).
*** Panel A. Negative Binomial ML Estimates with country Fixed-Effects
**************************************************************************************************************************************************


** All events; all ethnic homelands; columns (1)-(6)
*************************************************************************************************************************************************************************
esttab alnb1 alnb2 alnb3  alnb4 alnb5 alnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_2Aa.tex


** All events; ethnic homelands close to the border. columns (7)-(12)
*************************************************************************************************************************************************************************	   
esttab alnb1c alnb2c alnb3c  alnb4c alnb5c alnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_2Ab.tex
   
   
   
   
**2B- Estimate Baseline Regressions. Dependent Variable. Indicator for country-ethnic homelands experencing a conflict event (of any type)
*************************************************************************************************************************************************************************
** Panel B - Linear Probability Models with CGMREG
*************************************************************************************************************************************************************************

*** All Events.
xi: cgmreg alldum  	split10pc spil 		$simple                     					,  cluster(adm0_a3  cluster)
est store allp1

xi: cgmreg alldum  	split10pc spil 		$simple                  i.adm0_a3				,  cluster(adm0_a3  cluster)
est store allp2

xi: cgmreg alldum 	split10pc spil 		$simple         $location i.adm0_a3				,  cluster(adm0_a3  cluster)
est store allp3

xi: cgmreg alldum 	split10pc spil 		$simple  $rich1 $location i.adm0_a3				,  cluster(adm0_a3  cluster)
est store allp4

xi: cgmreg alldum 	split10pc spil		$simple  $rich1 $location i.adm0_a3 if all<top_all,  cluster(adm0_a3  cluster)
est store allp5

xi: cgmreg alldum 	split10pc spil 		$simple  $rich1 $location i.adm0_a3 if capital==0,  cluster(adm0_a3  cluster)
est store allp6

**
xi: cgmreg alldum  	split10pc spil 		$simple                           if borderdist<median_bd  & no==0					,  cluster(adm0_a3  cluster)
est store allp1c

xi: cgmreg alldum  	split10pc spil 		$simple                   i.adm0_a3 if borderdist<median_bd  & no==0				,  cluster(adm0_a3  cluster)
est store allp2c

xi: cgmreg alldum 	split10pc spil 		$simple         $location i.adm0_a3 if borderdist<median_bd  & no==0				,  cluster(adm0_a3  cluster)
est store allp3c

xi: cgmreg alldum 	split10pc spil 		$simple  $rich1 $location i.adm0_a3 if borderdist<median_bd  & no==0				,  cluster(adm0_a3  cluster)
est store allp4c

xi: cgmreg alldum 	split10pc spil 		$simple  $rich1 $location i.adm0_a3 if all<top_all & borderdist<median_bd  & no==0	,  cluster(adm0_a3  cluster)
est store allp5c

xi: cgmreg alldum 	split10pc spil 		$simple  $rich1 $location i.adm0_a3 if capital==0 & borderdist<median_bd  & no==0	,  cluster(adm0_a3  cluster)
est store allp6c


*** Table 2. Baseline Country Fixed-Effects Estimates (ACLED).
*** Panel B. Linear Probability Model (LPM) Estimates with country Fixed-Effects
*************************************************************************************************************************************************************************

** All events (reported in Panel B-Table 2)
*****************************************************************************************
esttab allp1 allp2 allp3 allp4   allp5 allp6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_2Ba.tex

esttab allp1c allp2c allp3c allp4c   allp5c allp6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(r2_a N , fmt(%9.3f %9.0g) labels(adjusted R-square)) keep(split10pc spil ) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_2Bb.tex
   
   
   
   
   
*---------------------------------------------------------------------------------------------------------------------------------------------------------------


** Table 3 - Civil Conflict: Introducing colonial variable - Negative binomial estimates
********************************************************************************************
***************************************************************************************************************************************************************************************


*************************************************************************************************************************************************************************
*** Panel A - Negative Binomial ML Estimates with country Fixed-Effects
*************************************************************************************************************************************************************************


// xi: nbreg all  	split10pc spil 		french_col british_col mixed_col  $simple                     					,  robust cluster(  cluster)
// est store alnb1

xi: nbreg all  	split10pc spil 		french_col british_col mixed_col  $simple                  i.adm0_a3 				,  robust cluster(  cluster)
est store alnb2

xi: nbreg all 	split10pc spil 		french_col british_col mixed_col  $simple         $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb3

xi: nbreg all 	split10pc spil 		french_col british_col mixed_col  $simple  $rich1 $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb4

xi: nbreg all 	split10pc spil		french_col british_col mixed_col  $simple  $rich1 $location i.adm0_a3 if all<top_all,  robust cluster(  cluster)
est store alnb5

xi: nbreg all 	split10pc spil 		french_col british_col mixed_col  $simple  $rich1 $location i.adm0_a3 if capital==0,  robust cluster(  cluster)
est store alnb6

**
// xi: nbreg all  	split10pc spil 		french_col british_col mixed_col  $simple                           if borderdist<median_bd  & no==0					,  robust cluster(  cluster)
// est store alnb1c

xi: nbreg all  	split10pc spil 		french_col british_col mixed_col  $simple                   i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb2c

xi: nbreg all 	split10pc spil 		french_col british_col mixed_col  $simple         $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb3c

xi: nbreg all 	split10pc spil 		french_col british_col mixed_col  $simple  $rich1 $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb4c

xi: nbreg all 	split10pc spil 		french_col british_col mixed_col  $simple  $rich1 $location i.adm0_a3 if all<top_all & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb5c

xi: nbreg all 	split10pc spil 		french_col british_col mixed_col  $simple  $rich1 $location i.adm0_a3 if capital==0 & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb6c



** All events; all ethnic homelands; columns (1)-(6)
*************************************************************************************************************************************************************************
esttab alnb2 alnb3  alnb4 alnb5 alnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil french_col british_col mixed_col) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_3Aa.tex


** All events; ethnic homelands close to the border. columns (7)-(12)
*************************************************************************************************************************************************************************	   
esttab alnb2c alnb3c  alnb4c alnb5c alnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil french_col british_col mixed_col) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_3Ab.tex
   

*************************************************************************************************************************************************************************
*** Panel B - Interacting French influence and relevant variables 
*************************************************************************************************************************************************************************
// frenchXsplit frenchXspillover
gen frenchXsplit = french_col*split10pc
gen frenchXspillover = french_col*spil

// xi: nbreg all  	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple                     					,  robust cluster(  cluster)
// est store alnb1

xi: nbreg all  	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple                  i.adm0_a3 				,  robust cluster(  cluster)
est store alnb2

xi: nbreg all 	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple         $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb3

xi: nbreg all 	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple  $rich1 $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb4

xi: nbreg all 	split10pc spil		french_col frenchXsplit frenchXspillover  $simple  $rich1 $location i.adm0_a3 if all<top_all,  robust cluster(  cluster)
est store alnb5

xi: nbreg all 	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple  $rich1 $location i.adm0_a3 if capital==0,  robust cluster(  cluster)
est store alnb6

**
// xi: nbreg all  	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple                           if borderdist<median_bd  & no==0					,  robust cluster(  cluster)
// est store alnb1c

xi: nbreg all  	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple                   i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb2c

xi: nbreg all 	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple         $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb3c

xi: nbreg all 	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple  $rich1 $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb4c

xi: nbreg all 	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple  $rich1 $location i.adm0_a3 if all<top_all & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb5c

xi: nbreg all 	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple  $rich1 $location i.adm0_a3 if capital==0 & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb6c



** All events; all ethnic homelands; columns (1)-(6)
*************************************************************************************************************************************************************************
esttab alnb2 alnb3  alnb4 alnb5 alnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood))  keep(split10pc spil french_col frenchXsplit frenchXspillover ) interaction(" X ") starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_3Ba.tex


** All events; ethnic homelands close to the border. columns (7)-(12)
*************************************************************************************************************************************************************************	   
esttab alnb2c alnb3c  alnb4c alnb5c alnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil french_col frenchXsplit frenchXspillover) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_3Bb.tex
   

   
   
   
*************************************************************************************************************************************************************************
*** Panel C - Interacting British influence and relevant variables  
*************************************************************************************************************************************************************************
// british_col britishXsplit britishXspillover

gen britishXsplit = british_col*split10pc
gen britishXspillover = british_col*spil

// xi: nbreg all  	split10pc spil 		british_col britishXsplit britishXspillover  $simple                     					,  robust cluster(  cluster)
// est store alnb1

xi: nbreg all  	split10pc spil 		british_col britishXsplit britishXspillover  $simple                  i.adm0_a3 				,  robust cluster(  cluster)
est store alnb2

xi: nbreg all 	split10pc spil 		british_col britishXsplit britishXspillover  $simple         $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb3

xi: nbreg all 	split10pc spil 		british_col britishXsplit britishXspillover  $simple  $rich1 $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb4

xi: nbreg all 	split10pc spil		british_col britishXsplit britishXspillover  $simple  $rich1 $location i.adm0_a3 if all<top_all,  robust cluster(  cluster)
est store alnb5

xi: nbreg all 	split10pc spil 		british_col britishXsplit britishXspillover  $simple  $rich1 $location i.adm0_a3 if capital==0,  robust cluster(  cluster)
est store alnb6

**
// xi: nbreg all  	split10pc spil 		british_col britishXsplit britishXspillover  $simple                           if borderdist<median_bd  & no==0					,  robust cluster(  cluster)
// est store alnb1c

xi: nbreg all  	split10pc spil 		british_col britishXsplit britishXspillover  $simple                   i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb2c

xi: nbreg all 	split10pc spil 		british_col britishXsplit britishXspillover  $simple         $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb3c

xi: nbreg all 	split10pc spil 		british_col britishXsplit britishXspillover  $simple  $rich1 $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb4c

xi: nbreg all 	split10pc spil 		british_col britishXsplit britishXspillover  $simple  $rich1 $location i.adm0_a3 if all<top_all & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb5c

xi: nbreg all 	split10pc spil 		british_col britishXsplit britishXspillover  $simple  $rich1 $location i.adm0_a3 if capital==0 & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb6c



** All events; all ethnic homelands; columns (1)-(6)
*************************************************************************************************************************************************************************
esttab alnb2 alnb3  alnb4 alnb5 alnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil british_col britishXsplit britishXspillover) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_3Ca.tex


** All events; ethnic homelands close to the border. columns (7)-(12)
*************************************************************************************************************************************************************************	   
esttab alnb2c alnb3c  alnb4c alnb5c alnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil british_col britishXsplit britishXspillover) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_3Cb.tex


*************************************************************************************************************************************************************************
*** Panel D - Interacting "mixed" influence and spil 
*************************************************************************************************************************************************************************

gen mixedXsplit = mixed_col*split10pc
gen mixedXspillover = mixed_col*spil


// xi: nbreg all  	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple                     					,  robust cluster(  cluster)
// est store alnb1

xi: nbreg all  	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple                  i.adm0_a3 				,  robust cluster(  cluster)
est store alnb2

xi: nbreg all 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple         $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb3

xi: nbreg all 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple  $rich1 $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb4

xi: nbreg all 	split10pc spil		mixed_col mixedXsplit mixedXspillover  $simple  $rich1 $location i.adm0_a3 if all<top_all,  robust cluster(  cluster)
est store alnb5

xi: nbreg all 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple  $rich1 $location i.adm0_a3 if capital==0,  robust cluster(  cluster)
est store alnb6

**
// xi: nbreg all  	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple                           if borderdist<median_bd  & no==0					,  robust cluster(  cluster)
// est store alnb1c

xi: nbreg all  	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple                   i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb2c

xi: nbreg all 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple         $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb3c

xi: nbreg all 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple  $rich1 $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb4c

xi: nbreg all 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple  $rich1 $location i.adm0_a3 if all<top_all & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb5c

xi: nbreg all 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple  $rich1 $location i.adm0_a3 if capital==0 & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb6c


** All events; all ethnic homelands; columns (1)-(6)
*************************************************************************************************************************************************************************
esttab alnb2 alnb3  alnb4 alnb5 alnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil mixed_col mixedXsplit mixedXspillover) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_3Da.tex


** All events; ethnic homelands close to the border. columns (7)-(12)
*************************************************************************************************************************************************************************	   
esttab alnb2c alnb3c  alnb4c alnb5c alnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil mixed_col mixedXsplit mixedXspillover) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_3Db.tex



*---------------------------------------------------------------------------------------------------------------------------------------------------------------


** Table 4 - Fatalities: Introducing colonial variable - Negative binomial estimates
********************************************************************************************
***************************************************************************************************************************************************************************************


*************************************************************************************************************************************************************************
*** Panel A - Negative Binomial ML Estimates with country Fixed-Effects
*************************************************************************************************************************************************************************


// xi: nbreg all  	split10pc spil 		french_col british_col mixed_col  $simple                     					,  robust cluster(  cluster)
// est store alnb1

xi: nbreg fatalities   	split10pc spil 		french_col british_col mixed_col  $simple                  i.adm0_a3 				,  robust cluster(  cluster)
est store alnb2

xi: nbreg fatalities  	split10pc spil 		french_col british_col mixed_col  $simple         $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb3

xi: nbreg fatalities  	split10pc spil 		french_col british_col mixed_col  $simple  $rich1 $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb4

xi: nbreg fatalities  	split10pc spil		french_col british_col mixed_col  $simple  $rich1 $location i.adm0_a3 if fatalities <top_fatalities,  robust cluster(  cluster)
est store alnb5

xi: nbreg fatalities  	split10pc spil 		french_col british_col mixed_col  $simple  $rich1 $location i.adm0_a3 if capital==0,  robust cluster(  cluster)
est store alnb6

**
// xi: nbreg all  	split10pc spil 		french_col british_col mixed_col  $simple                           if borderdist<median_bd  & no==0					,  robust cluster(  cluster)
// est store alnb1c

xi: nbreg fatalities   	split10pc spil 		french_col british_col mixed_col  $simple                   i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb2c

xi: nbreg fatalities  	split10pc spil 		french_col british_col mixed_col  $simple         $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb3c

xi: nbreg fatalities  	split10pc spil 		french_col british_col mixed_col  $simple  $rich1 $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb4c

xi: nbreg fatalities  	split10pc spil 		french_col british_col mixed_col  $simple  $rich1 $location i.adm0_a3 if fatalities <top_fatalities & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb5c

xi: nbreg fatalities  	split10pc spil 		french_col british_col mixed_col  $simple  $rich1 $location i.adm0_a3 if capital==0 & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb6c



** All events; all ethnic homelands; columns (1)-(6)
*************************************************************************************************************************************************************************
esttab alnb2 alnb3  alnb4 alnb5 alnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil french_col british_col mixed_col) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_4Aa.tex


** All events; ethnic homelands close to the border. columns (7)-(12)
*************************************************************************************************************************************************************************	   
esttab alnb2c alnb3c  alnb4c alnb5c alnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil french_col british_col mixed_col) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_4Ab.tex
   

*************************************************************************************************************************************************************************
*** Panel B - Interacting French influence and relevant variables 
*************************************************************************************************************************************************************************
// frenchXsplit frenchXspillover
// gen frenchXsplit = french_col*split10pc
// gen frenchXspillover = french_col*spil

// xi: nbreg all  	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple                     					,  robust cluster(  cluster)
// est store alnb1

xi: nbreg fatalities   	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple                  i.adm0_a3 				,  robust cluster(  cluster)
est store alnb2

xi: nbreg fatalities  	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple         $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb3

xi: nbreg fatalities  	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple  $rich1 $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb4

xi: nbreg fatalities  	split10pc spil		french_col frenchXsplit frenchXspillover  $simple  $rich1 $location i.adm0_a3 if fatalities <top_fatalities,  robust cluster(  cluster)
est store alnb5

xi: nbreg fatalities 	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple  $rich1 $location i.adm0_a3 if capital==0,  robust cluster(  cluster)
est store alnb6

**
// xi: nbreg all  	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple                           if borderdist<median_bd  & no==0					,  robust cluster(  cluster)
// est store alnb1c

xi: nbreg fatalities  	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple                   i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb2c

xi: nbreg fatalities 	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple         $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb3c

xi: nbreg fatalities 	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple  $rich1 $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb4c

xi: nbreg fatalities 	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple  $rich1 $location i.adm0_a3 if all<top_fatalities & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb5c

xi: nbreg fatalities 	split10pc spil 		french_col frenchXsplit frenchXspillover  $simple  $rich1 $location i.adm0_a3 if capital==0 & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb6c



** All events; all ethnic homelands; columns (1)-(6)
*************************************************************************************************************************************************************************
esttab alnb2 alnb3  alnb4 alnb5 alnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood))  keep(split10pc spil french_col frenchXsplit frenchXspillover ) interaction(" X ") starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_4Ba.tex


** All events; ethnic homelands close to the border. columns (7)-(12)
*************************************************************************************************************************************************************************	   
esttab alnb2c alnb3c  alnb4c alnb5c alnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil french_col frenchXsplit frenchXspillover) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_4Bb.tex
   

   
   
   
*************************************************************************************************************************************************************************
*** Panel C - Interacting British influence and relevant variables  
*************************************************************************************************************************************************************************
// british_col britishXsplit britishXspillover

// gen britishXsplit = british_col*split10pc
// gen britishXspillover = british_col*spil

// xi: nbreg all  	split10pc spil 		british_col britishXsplit britishXspillover  $simple                     					,  robust cluster(  cluster)
// est store alnb1

xi: nbreg fatalities  	split10pc spil 		british_col britishXsplit britishXspillover  $simple                  i.adm0_a3 				,  robust cluster(  cluster)
est store alnb2

xi: nbreg fatalities 	split10pc spil 		british_col britishXsplit britishXspillover  $simple         $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb3

xi: nbreg fatalities 	split10pc spil 		british_col britishXsplit britishXspillover  $simple  $rich1 $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb4

xi: nbreg fatalities 	split10pc spil		british_col britishXsplit britishXspillover  $simple  $rich1 $location i.adm0_a3 if all<top_fatalities,  robust cluster(  cluster)
est store alnb5

xi: nbreg fatalities 	split10pc spil 		british_col britishXsplit britishXspillover  $simple  $rich1 $location i.adm0_a3 if capital==0,  robust cluster(  cluster)
est store alnb6

**
// xi: nbreg all  	split10pc spil 		british_col britishXsplit britishXspillover  $simple                           if borderdist<median_bd  & no==0					,  robust cluster(  cluster)
// est store alnb1c

xi: nbreg fatalities  	split10pc spil 		british_col britishXsplit britishXspillover  $simple                   i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb2c

xi: nbreg fatalities 	split10pc spil 		british_col britishXsplit britishXspillover  $simple         $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb3c

xi: nbreg fatalities 	split10pc spil 		british_col britishXsplit britishXspillover  $simple  $rich1 $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb4c

xi: nbreg fatalities 	split10pc spil 		british_col britishXsplit britishXspillover  $simple  $rich1 $location i.adm0_a3 if all<top_fatalities & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb5c

xi: nbreg fatalities 	split10pc spil 		british_col britishXsplit britishXspillover  $simple  $rich1 $location i.adm0_a3 if capital==0 & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb6c



** All events; all ethnic homelands; columns (1)-(6)
*************************************************************************************************************************************************************************
esttab alnb2 alnb3  alnb4 alnb5 alnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil british_col britishXsplit britishXspillover) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_4Ca.tex


** All events; ethnic homelands close to the border. columns (7)-(12)
*************************************************************************************************************************************************************************	   
esttab alnb2c alnb3c  alnb4c alnb5c alnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil british_col britishXsplit britishXspillover) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_4Cb.tex


*************************************************************************************************************************************************************************
*** Panel D - Interacting "mixed" influence and spil 
*************************************************************************************************************************************************************************

// gen mixedXsplit = mixed_col*split10pc
// gen mixedXspillover = mixed_col*spil


// xi: nbreg all  	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple                     					,  robust cluster(  cluster)
// est store alnb1

xi: nbreg fatalities  	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple                  i.adm0_a3 				,  robust cluster(  cluster)
est store alnb2

xi: nbreg fatalities 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple         $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb3

xi: nbreg fatalities 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple  $rich1 $location i.adm0_a3				,  robust cluster(  cluster)
est store alnb4

xi: nbreg fatalities 	split10pc spil		mixed_col mixedXsplit mixedXspillover  $simple  $rich1 $location i.adm0_a3 if all<top_fatalities,  robust cluster(  cluster)
est store alnb5

xi: nbreg fatalities 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple  $rich1 $location i.adm0_a3 if capital==0,  robust cluster(  cluster)
est store alnb6

**
// xi: nbreg all  	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple                           if borderdist<median_bd  & no==0					,  robust cluster(  cluster)
// est store alnb1c

xi: nbreg fatalities  	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple                   i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb2c

xi: nbreg fatalities 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple         $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb3c

xi: nbreg fatalities 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple  $rich1 $location i.adm0_a3 if borderdist<median_bd  & no==0				,  robust cluster(  cluster)
est store alnb4c

xi: nbreg fatalities 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple  $rich1 $location i.adm0_a3 if all<top_fatalities & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb5c

xi: nbreg fatalities 	split10pc spil 		mixed_col mixedXsplit mixedXspillover  $simple  $rich1 $location i.adm0_a3 if capital==0 & borderdist<median_bd  & no==0	,  robust cluster(  cluster)
est store alnb6c


** All events; all ethnic homelands; columns (1)-(6)
*************************************************************************************************************************************************************************
esttab alnb2 alnb3  alnb4 alnb5 alnb6 , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil mixed_col mixedXsplit mixedXspillover) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_4Da.tex


** All events; ethnic homelands close to the border. columns (7)-(12)
*************************************************************************************************************************************************************************	   
esttab alnb2c alnb3c  alnb4c alnb5c alnb6c , cells(b(star fmt(%9.4f)) se(par) t(fmt(%9.2f)))   ///
       stats(ll N , fmt(%9.3f %9.0g) labels(Log Likelihood)) keep(split10pc spil mixed_col mixedXsplit mixedXspillover) starlevels(* 0.1 ** 0.05  *** 0.01) ///
	   style(tex) replace, using Table_4Db.tex



