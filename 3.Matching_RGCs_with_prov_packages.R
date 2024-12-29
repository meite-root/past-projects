#**********************************************************************************************#
#********************* SETUP:   Clean workspace & set directory          **********************#
#**********************************************************************************************#

# Clear console with control + L
rm(list=ls())
setwd("/Users/hassanemeite/Documents/To Phd:Masters/Zambia - Rural Electrification Collaborative Research project")



#**********************************************************************************************************************#
#*************************          TASK 3:   Rural growth centres (RGCs) in Zambia          ************************#
#**********************************************************************************************************************#

#*********  0.
rm(list=ls())
setwd("/Users/hassanemeite/Documents/To Phd:Masters/Zambia - Rural Electrification Collaborative Research project")

#*********  1.Install & Load Packages

#install.packages("zoo")
#install.packages("haven")
#install.packages("data.table")

require(zoo)
require(haven)
require(data.table)


#*********  2. Load File & clean
rgc_list<- fread("RGC_list.csv")
rgc_list[,c("V11","V12","V13","V14") :=NULL] # Remove columns
setkey(rgc_list,Ranking) # Order rows




#*********  3. Add "Top_prio" column
#* it is a variable indicating whether each RGC is or is not (0/1 dummy) part of the the top priority RGCs  ( Table 4-3, page  86, JICA-REMP MAIN-2009.pdf).

rgc_list[, top_prio := 0]

rgc_list[RGC=="Shimukuni", top_prio := 1]
rgc_list[RGC=="Mpima Dairy Scheme Shed", top_prio := 1] #Changed from "Mpima" to "Mpima Dairy Scheme Shed"
rgc_list[RGC=="Chipepo" & District =="Kapiri Mposhi", top_prio := 1]
rgc_list[RGC=="Old Mkushi (Luano)", top_prio := 1] #Changed from "Old Mkushi" to "Old Mkushi (Luano)""
rgc_list[RGC=="Big Concession", top_prio := 1] #Changed from "Mumbwa Big Concession" to "Big Concession"
rgc_list[RGC=="Chibale" & District =="Serenje", top_prio := 1] # RGC name appears in two districts so needed precision
rgc_list[RGC=="Mingomba", top_prio := 1] #Changed from "Mungomba" to "Mingomba"
rgc_list[RGC=="Kamiteta", top_prio := 1]
rgc_list[RGC=="Kameme", top_prio := 1]
rgc_list[RGC=="Kakolo", top_prio := 1]
rgc_list[RGC=="Kafubu", top_prio := 1]
rgc_list[RGC=="Emerald Mining Area", top_prio := 1]
rgc_list[RGC=="Mutaba", top_prio := 1]
rgc_list[RGC=="Mikata", top_prio := 1]
rgc_list[RGC=="Mutundu North (Conner Bar)", top_prio := 1] #Changed from "Mutundu North" to "Mutundu North (Conner Bar)" 
rgc_list[RGC=="Kanglonga", top_prio := 1]
rgc_list[RGC=="Mlolo", top_prio := 1]
rgc_list[RGC=="Kalinkhu", top_prio := 1]
rgc_list[RGC=="Chiparamba", top_prio := 1]
rgc_list[RGC=="Kagoro", top_prio := 1]
rgc_list[RGC=="Mwase", top_prio := 1]
rgc_list[RGC=="Mphomwa Tse-tse", top_prio := 1]
rgc_list[RGC=="Chipembe", top_prio := 1]
rgc_list[RGC=="Kapungwe", top_prio := 1]
rgc_list[RGC=="Lupiya", top_prio := 1]
rgc_list[RGC=="Chama" & District =="Kawambwa", top_prio := 1] # RGC name appears in two districts so needed precision
rgc_list[RGC=="Kasongwa sub boma", top_prio := 1] #Changed from "Kasongwa Sub Boma" to "Kasongwa sub boma"
rgc_list[RGC=="Talayi", top_prio := 1] #Changed from "Tayali" to "Talayi"
rgc_list[RGC=="Katuta", top_prio := 1]
rgc_list[RGC=="Chilongo (Mtepuke)", top_prio := 1] #Changed from "Chilongo" to "Chilongo (Mtepuke)"
rgc_list[RGC=="Chinsanka", top_prio := 1]
rgc_list[RGC=="Chinyunyu", top_prio := 1]
rgc_list[RGC=="Chipapa VC", top_prio := 1] #Changed from "Chipapa" to "Chipapa VC"
rgc_list[RGC=="Luangwa Sec", top_prio := 1] # Changed from "Luangwa Boma" to "Luangwa Sec"
rgc_list[RGC=="Kambashi", top_prio := 1]
rgc_list[RGC=="Shiwan'gandu area", top_prio := 1] # Changed from "Shiwangandu" to "Shiwan'gandu area"
rgc_list[RGC=="Muyombe", top_prio := 1]
rgc_list[RGC=="Nsama Sub Boma", top_prio := 1]
rgc_list[RGC=="Kachuma", top_prio := 1]
rgc_list[RGC=="Masonde Farming Block", top_prio := 1] # Changed from "Masonde" to "Masonde Farming Block"
rgc_list[RGC=="Chimula", top_prio := 1]
rgc_list[RGC=="Kanchibiya Farm Block", top_prio := 1] # Changed from "Kanchibiya" to "Kanchibiya Farm Block"
rgc_list[RGC=="Mukupa Kaoma", top_prio := 1] # Changed to "Mukupa Kaoma" in "Lunte" district; while table 4-3 (p.86) indicates "Mukupakaoma" to be in "Mporokoso" district
rgc_list[RGC=="Kasaba Bay", top_prio := 1]
rgc_list[RGC=="Makasa", top_prio := 1]
rgc_list[RGC=="Wulongo", top_prio := 1]
rgc_list[RGC=="Chivombo", top_prio := 1]
rgc_list[RGC=="Kashinakazhi", top_prio := 1]
rgc_list[RGC=="Nselauke", top_prio := 1]
rgc_list[RGC=="Matushi", top_prio := 1]
rgc_list[RGC=="Ntambu", top_prio := 1]
rgc_list[RGC=="Mumena", top_prio := 1]
rgc_list[RGC=="Chitokoloki", top_prio := 1]
rgc_list[RGC=="Kanchomba", top_prio := 1] # Changed from "Kachomba" to "Kanchomba"
rgc_list[RGC=="Siabwengo", top_prio := 1]
rgc_list[RGC=="No.57  (Lubanda)", top_prio := 1] # Changed from "Lubanda" to "No.57  (Lubanda)""
rgc_list[RGC=="Napatizya", top_prio := 1]
rgc_list[RGC=="Mambova", top_prio := 1]
rgc_list[RGC=="Kasiya", top_prio := 1]
rgc_list[RGC=="Ngwezi", top_prio := 1]
rgc_list[RGC=="Muzuri (Kamuzya East)", top_prio := 1]  # Changed from "Kamuzya East" to "Muzuri (Kamuzya East)"
rgc_list[RGC=="Baambwe", top_prio := 1] # Changed from "Bambwe" to "Baambwe"
rgc_list[RGC=="Namoomba", top_prio := 1]
rgc_list[RGC=="Sinakaimbi", top_prio := 1]
rgc_list[RGC=="Sikongo", top_prio := 1]
rgc_list[RGC=="Nkeyama", top_prio := 1]
rgc_list[RGC=="Lukulu Township", top_prio := 1] # Changed from "Lukulu Boma" to "Lukulu Township"
rgc_list[RGC=="Nangula", top_prio := 1]
rgc_list[RGC=="Sianda", top_prio := 1]
rgc_list[RGC=="Sichili", top_prio := 1]
rgc_list[RGC=="Shangombo", top_prio := 1] # Changed from "Shang'ombo" to "Shangombo"



#* Test : Upon completing this task by taking information the the Table 4-3 we realize that we could obtain the very same list by looking at the observations
#* with Priority 1 in the list. Hence, these two are the same:
#* top_priority_RGCs <- rgc_list[top_prio==1]
#* top_priority_RGCs_2 <- rgc_list[Priority == 1]


#*********  2. Merge the RGC list and the Provincial Packages information into "RGC_fullinfo"

#*** 1. Loading Provincial Packages information

prov_packages <- fread("Provincial packages.csv") # Upload Provincial package info


#*** 2. Check for duplicates 

# rgc_list
setkey(prov_packages,RGC,Province)
duplicates_provpack <- prov_packages[duplicated(prov_packages,by = key(prov_packages))==TRUE]
# prov_package
setkey(rgc_list,RGC,Province)
duplicates_rgclist <- rgc_list[duplicated(rgc_list,by = key(rgc_list))==TRUE]

#***3. Correcting for duplicates

prov_packages[ RGC=="Chama"  & prov_package ==9, RGC :="Chama 1"]
rgc_list[ RGC=="Chama"  & District =="Kawambwa", RGC :="Chama 1"]

prov_packages[ RGC=="Chikowa"  & prov_package ==18, RGC :="Chikowa 3"]
rgc_list[ RGC=="Chikowa"  & District =="Petauke", RGC :="Chikowa 3"]

prov_packages[ RGC=="Kawama"  & prov_package ==10, RGC :="Kawama 2"]
rgc_list[ RGC=="Kawama"  & District =="Luanshya", RGC :="Kawama 2"]

prov_packages[ RGC=="Lukwesa"  & prov_package ==6, RGC :="Lukwesa 2"]
rgc_list[ RGC=="Lukwesa"  & District =="Mwense", RGC :="Lukwesa 2"]

prov_packages[ RGC=="Mano"  & prov_package ==16, RGC :="Mano 2"]
rgc_list[ RGC=="Mano"  & District =="Mansa", RGC :="Mano 2"]

prov_packages[ RGC=="Mwamba"  & prov_package ==32, RGC :="Mwamba 2"]
rgc_list[ RGC=="Mwamba"  & District =="Mbala", RGC :="Mwamba 2"]

prov_packages[ RGC=="Mwandi"  & prov_package ==19, RGC :="Mwandi 2"]
rgc_list[ RGC=="Mwandi"  & District =="Sesheke", RGC :="Mwandi 2"]

prov_packages[ RGC=="Sinde"  & prov_package ==15, RGC :="Sinde 2"]
rgc_list[ RGC=="Sinde"  & District =="Livingstone", RGC :="Sinde 2"]



#*** 4. Solve remaining

#--B. Identify issues one by one and Solve

#1.Chipundu
# In prov_packages, we have: (Chipundu  | 16 (Serenje)) & (Chipundu  | 17 (Serenje))  
# In rgclist,       we have: (Chipundu | Chitambo)(-> Serenje in Map) & (Chipundu | Milenge)(-> not geo coded)

# -> delete Chipundu | Milenge (rgc_list) and switch to Chipundu | Chitambo to Chipundu | Serenje
# -> delete one instance of Chipundu Chipundu | Serenje (prov_package)
rgc_list[RGC == "Chipundu" & District =="Milenge", delete :="Yes"][RGC == "Chipundu" & District =="Chitambo",District :="Serenje"]
prov_packages[RGC == "Chipundu" & prov_package ==17, delete :="Yes"]


#2.Kangalati
# in prov_packages, we have: (Kangalati | 10 (Luanshya)), (Kangalati | 13 (Lufwanyama))
# in rgclist,       we have: (Kangalati | Lufwanyama | DML: 96,907)(-> not geo coded) & (Kangalati_ | Lufwanyama | DML: 175,512)(-> not geo coded)


# -> Assume the higher the DML, the lower the Prov_package number
prov_packages[RGC == "Kangalati" & prov_package ==13, RGC :="Kangalati"] #DML:96,907
prov_packages[RGC == "Kangalati" & prov_package ==10, RGC :="Kangalati_"] #DML:175,512
# -> Rename to 1 and 2 instead of "_"
prov_packages[RGC == "Kangalati", RGC :="Kangalati 1"]
rgc_list[RGC == "Kangalati", RGC :="Kangalati 1"]
prov_packages[RGC == "Kangalati_", RGC :="Kangalati 2"]
rgc_list[RGC == "Kangalati_", RGC :="Kangalati 2"]


#3.Kansoka
# in prov_packages,  we have: Kansoka | 5 (Chililabombwe), Kansoka | 9 (Chingola) , Kansoka | 12 (Kitwe)
# in the rgclist,    we have: (Kansoka | Lufwanyama | DML: 293,555)(-> Lufwanyama on map) , (Kansoka_ | Lufwanyama | DML: 187,522)(-> Lufwanyama on map) & (Kansoka__ | Lufwanyama | DML: 195,180)(-> not geo coded).


# -> Assume the higher the DML, the lower the Prov_package number
prov_packages[RGC == "Kansoka" & prov_package ==12, RGC :="Kansoka_"] #DML:187,522
prov_packages[RGC == "Kansoka" & prov_package ==9, RGC :="Kansoka__"] #DML:195,180
prov_packages[RGC == "Kansoka" & prov_package ==5, RGC :="Kansoka"] #DML:293,555
# -> Rename to 1,2, & 3 instead of "_", "__"
prov_packages[RGC == "Kansoka", RGC :="Kansoka 1"]
rgc_list[RGC == "Kansoka", RGC :="Kansoka 1"]
prov_packages[RGC == "Kansoka_", RGC :="Kansoka 2"]
rgc_list[RGC == "Kansoka_", RGC :="Kansoka 2"]
prov_packages[RGC == "Kansoka__", RGC :="Kansoka 3"]
rgc_list[RGC == "Kansoka__", RGC :="Kansoka 3"]



#4. Maguya
# in prov_packages, we have: (Maguya | 7 (Chipata)) &  (Maguya | 22 (Chipata)). 
# in the rgclist,   we have: (Maguya | Chipata | DML:219,611 ) (-> Chipata on map) &  (Maguya 2| Chipata | DML:171,095) (-> Chipata on map).


# -> Assume the higher the DML, the lower the Prov_package number
prov_packages[RGC == "Maguya" & prov_package ==22, RGC :="Maguya 2"] #DML:171,095
prov_packages[RGC == "Maguya" & prov_package ==7, RGC :="Maguya"] #DML:219,611
# -> Rename to 1 and 2 
prov_packages[RGC == "Maguya", RGC :="Maguya 1"]
rgc_list[RGC == "Maguya", RGC :="Maguya 1"]



#5. Luela
# in prov_packages, we have: Luela | 3 (Kitwe) &  Luela | 14 (Mbongwe).
# on the list, we have: (Luela | Kalulushi | DML: 231,632) (-> Kalulushi on map), (Luela | Lufwanyama | DML:43,332 ) (-> not geo-coded).


# -> Assume the higher the DML, the lower the Prov_package number

rgc_list[RGC == "Luela" & District =="Lufwanyama", RGC :="Luela 1"]
prov_packages[RGC == "Luela" & prov_package ==14, RGC :="Luela 1"] 

rgc_list[RGC == "Luela" & District =="Kalulushi", RGC :="Luela 2"]
prov_packages[RGC == "Luela" & prov_package ==3, RGC :="Luela 2"] 


#6. Masansa 
# in prov_packages, we have: (Masansa | 13 (Mkushi)) & (Masansa | 13 (Mkushi)) .
# on rgclist, we have (Masansa | Kapiri Mposhi | DML: 499,270) -> (Luano on Map) & (Masansa | Mkushi | DML: 309,065) -> (Mkushi on map)


# -> delete one instance of Masansa | 13 (Mkushi)
# -> Change Masansa | Kapiri Mposhi to Masansa 2
prov_packages[RGC == "Masansa" & duplicated(prov_packages,by = key(prov_packages))==TRUE, delete :="Yes" ]
rgc_list[RGC == "Masansa" & District =="Kapiri Mposhi", RGC :="Masansa 2"]



#7. *Milopa
# in prov_packages, we have: (Milopa | 9 (Chingola)) &  (Milopa | 12 (Kitwe)) .
# on rgclist, we have (Milopa | Lufwanyama | DML: 375,139 | Priority: 15)(-> Lufwanyama on map) & (Milopa | Lufwanyama| DML:196,375 | Priority: 5)(-> Lufwanyama on map)


# -> Assume the higher the DML, the lower the Prov_package number

rgc_list[RGC == "Milopa" & Priority ==5, RGC :="Milopa 1"] #DML:196,375 
prov_packages[RGC == "Milopa" & prov_package ==12, RGC :="Milopa 1"] 

rgc_list[RGC == "Milopa" & Priority ==15, RGC :="Milopa 2"] #DML: 375,139
prov_packages[RGC == "Milopa" & prov_package ==9, RGC :="Milopa 2"] 


#8. *Muchinshi
# in prov_packages, we have: (Muchinshi | 9 (Chingola)) &  (Muchinshi | 9 (Chingola)) .
# on rgclist, we have (Muchinshi | Chingola | DML: 636,432)(-> Chingola on map) & (Muchinshi | Lufwanyama| DML:58,076)(-> not geo coded)


# -> delete one instance of (Muchinshi | 9 (Chingola))
# -> delete (Muchinshi | Lufwanyama) in rgclist
setkey(prov_packages,RGC,Province)
prov_packages[RGC == "Muchinshi" & duplicated(prov_packages,by = key(prov_packages))==TRUE, delete :="Yes" ]
rgc_list[RGC == "Muchinshi" & District =="Lufwanyama", delete :="Yes" ]


#9. *Mutenda
# in prov_packages, we have: (Mutenda | 9 (Chingola)) &  (Mutenda | 9 (Chingola)) .
# on rgclist, we have (Mutenda | Chingola | DML: 1,078,866)(-> Chingola on map) & (Mutenda | Lufwanyama| DML:58,076)(-> not geo coded)

# -> delete one instance of (Mutenda | 9 (Chingola))
# -> delete (Mutenda | Lufwanyama| DML:58,076) in rgclist
setkey(prov_packages,RGC,Province)
prov_packages[RGC == "Mutenda" & duplicated(prov_packages,by = key(prov_packages))==TRUE, delete :="Yes" ]
rgc_list[RGC == "Mutenda" & District =="Lufwanyama", delete :="Yes" ]


#10. *Waya
# in prov_packages, we have: (Waya | 5 (Chibombo)) &  (Waya | 18 Chibombo) .
# on rgclist, we have (Waya | Chibombo | DML: 460,856)(-> Chibombo on map) & (Waya | Kapiri Mposhi| DML:192,982)(-> Kapiri Mposhi on map)

# -> Assume the higher the DML, the lower the Prov_package number
rgc_list[RGC == "Waya" & District =="Kapiri Mposhi" , RGC :="Waya 1"] #DML:192,982
prov_packages[RGC == "Waya" & prov_package ==18, RGC :="Waya 1"] 

rgc_list[RGC == "Waya" & District =="Chibombo", RGC :="Waya 2"] #DML:460,856
prov_packages[RGC == "Waya" & prov_package ==5, RGC :="Waya 2"] 

#--B. Delete what is to be deleted
rgc_list <- rgc_list[is.na(delete)]
prov_packages <- prov_packages[is.na(delete)]



#*** 5.  Check for duplicates 
# prov_package
setkey(prov_packages,RGC,Province)
duplicates_provpack <- prov_packages[duplicated(prov_packages,by = key(prov_packages))==TRUE]
# rgc_list
setkey(rgc_list,RGC,Province)
duplicates_rgclist <- rgc_list[duplicated(rgc_list,by = key(rgc_list))==TRUE]



#*** 6. Merge
RGC_fullinfo <- merge(prov_packages, rgc_list, by = c("RGC","Province"), all = TRUE)


#*** 7. Check unmatched
#correcting for typos
RGC_fullinfo <- RGC_fullinfo[,c("delete.x","delete.y") :=.(NULL,NULL)]
#rgc_list_unmatched
unmatched_rgc_list <- RGC_fullinfo[is.na(prov_package)]
setkey(unmatched_rgc_list, Province, RGC)
#prov_packages_unmatched
unmatched_prov_packages <- RGC_fullinfo[is.na(top_prio)]
setkey(unmatched_prov_packages, Province, RGC)
#Remove
rm(unmatched_prov_packages,unmatched_rgc_list)





#*** 8. FIND GPS coordinates of JICA REMP near_substations
rm(duplicates_provpack,duplicates_rgclist)


# C. Load IDENTIFIED JICA maps Substations
z.JICAmaps_stations <- geojsonsf::geojson_sf("/Users/hassanemeite/Dropbox/RA Hassane/substations_step2_identification.geojson")
z.JICAmaps_stations <- setDT(z.JICAmaps_stations)
z.JICAmaps_stations[, c("namematch_yxcoords","geometry"):= .(NULL,NULL)]

# D. Merge
RGC_fullinfo <- merge(RGC_fullinfo, z.JICAmaps_stations, by = c("near_substation"), all = TRUE)
RGC_fullinfo <- RGC_fullinfo[ !is.na(near_substation)]
rm(z.JICAmaps_stations)


# E. Check Merge

# -> Summarize substations
RGC_fullinfo[,count :=1]
z.list_subtations <- RGC_fullinfo[, ( V1 = sum(count)), by = c("near_substation","overlay_xycoords","nearby_turbosm_ss")][!is.na(near_substation)][,V1:=NULL]
setkey(z.list_subtations,near_substation)
# fwrite(list_subtations, "/Users/hassanemeite/Dropbox/RA Hassane/list_JICA_REMP_subtations.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)


# ---> z.JICAmaps_stations AS CSV & GEOJSON
 
# -> Export for use in QGIS 
z.list_subtations[!is.na(overlay_xycoords), xcoord := strsplit(as.character(overlay_xycoords), ",")[[1]][1], by = near_substation]
z.list_subtations[!is.na(overlay_xycoords), ycoord := strsplit(as.character(overlay_xycoords), ",")[[1]][2], by = near_substation]
z.list_subtations[is.na(ycoord), ycoord :=0][is.na(xcoord), xcoord :=0]
setkey(z.list_subtations,near_substation)
z.list_subtations.sf <- st_as_sf(z.list_subtations, coords = c("xcoord", "ycoord"), crs = 4326, agr = "constant")


#*** 9.SAVE
st_write(z.list_subtations.sf,"/Users/hassanemeite/Dropbox/RA Hassane/substations_JICA_identified.geojson") 
fwrite(RGC_fullinfo, "RGCs_provpackages_matched.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)









#***********************************************************************************************************#
#*********************      NEW RGC LIST: FIND REMAINING COORDINATES                   *********************#
#***********************************************************************************************************#

# Clear console with control + L
rm(list=ls())
setwd("/Users/hassanemeite/Documents/To Phd:Masters/Zambia - Rural Electrification Collaborative Research project")


#*********  1.Install & Load Packages
require(zoo)
require(haven)
require(data.table)


#******************************* 2.Uploading new list
rgc_list2 <- fread("RGC_list_new.csv")
setkey(rgc_list2,Ranking) # Order rows


#******************************* 3. FIND REMAINING COORDINATES

#********* Export for use in QGIS 
rgc_list2[, xcoord :=`X Coordinate`][, ycoord :=`Y Coordinate`][,`X Coordinate` := NULL][,`Y Coordinate` := NULL]
rgc_list2[,coords_from_overlay := "no"][ is.na(xcoord), coords_from_overlay :=""]
rgc_list2[coords_from_overlay =="", ycoord:= 0][coords_from_overlay =="", xcoord:= 0]


rgc_list2 <- st_as_sf(rgc_list2, coords = c("xcoord", "ycoord"), crs = 4326, agr = "constant")

# st_write(rgc_list2,"/Users/hassanemeite/Dropbox/RA Hassane/RGCs_nocoords.geojson") 

#********* QGIS - Finding coordinates

#********* MERGE new data with rgc_list2


#********* rgc_list2
# Load
rgc_list2 <- fread("RGC_list_new.csv")
rgc_list2[, source:="REA"] # Remove columns
setkey(rgc_list2,Ranking) # Order rows


#********* New found 180

# Load
additional_180 <- geojsonsf::geojson_sf("/Users/hassanemeite/Dropbox/RA Hassane/RGCs_nocoords_done.geojson")

# Trim
additional_180 <- setDT(additional_180)
additional_180 <- additional_180[coords_from_overlay != "no"]
additional_180 <- additional_180[,RGC := new_RGC][, c("RGC","coords_from_overlay")]

# Separate geometry values
additional_180 <- additional_180[,xcoord := strsplit(as.character(coords_from_overlay), ",")[[1]][1], by = RGC]
additional_180 <- additional_180[,ycoord := strsplit(as.character(coords_from_overlay), ",")[[1]][2], by = RGC]
additional_180 <- additional_180[, coords_from_overlay := NULL ]

# D. Merge
rgc_list2 <- merge(rgc_list2, additional_180, by = c("RGC"), all = TRUE)

# -> Blend added data
rgc_list2 <- rgc_list2[is.na(`X Coordinate`), source := "overlay"]
rgc_list2 <- rgc_list2[is.na(`X Coordinate`), `X Coordinate`:= xcoord]
rgc_list2 <- rgc_list2[is.na(`Y Coordinate`), `Y Coordinate`:= ycoord]
rgc_list2 <- rgc_list2[, xcoord := NULL][, ycoord := NULL]

# ->SAVE
fwrite(rgc_list2, "/Users/hassanemeite/Dropbox/RA Hassane/RGC_list_allcoords.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)
rm(additional_180)


#******************************* Check for duplicates in coordinates

setkey(rgc_list2,`X Coordinate`,`Y Coordinate`) # Order rows
rgc_list2[duplicated(rgc_list2,by = key(rgc_list2), fromLast=TRUE)==TRUE & !is.na(`X Coordinate`), source := "REA_duplicate"]
rgc_list2[duplicated(rgc_list2,by = key(rgc_list2), fromLast=FALSE)==TRUE & !is.na(`X Coordinate`), source := "REA_duplicate"]

fwrite(rgc_list2, "/Users/hassanemeite/Dropbox/RA Hassane/RGC_list_allcoords.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)


# E. Export for use in QGIS 
rgc_list2 <- rgc_list2[, note:=""]
rgc_list2noNA <- rgc_list2[!is.na(`X Coordinate`)]#  <--------- 8 of those
rgc_list2.sf <- st_as_sf(rgc_list2noNA, coords = c("X Coordinate", "Y Coordinate"), crs = 4326, agr = "constant")
rm(rgc_list2noNA)


st_write(rgc_list2.sf,"/Users/hassanemeite/Dropbox/RA Hassane/RGC_list_allcoords.geojson")
rm(rgc_list2.sf)
rgc_list2 <- rgc_list2[, note:= NULL]

# F. Import Back

REA_duplicates <- geojsonsf::geojson_sf("/Users/hassanemeite/Dropbox/RA Hassane/RGC_list_allcoords.geojson")
REA_duplicates <- setDT(REA_duplicates)
REA_duplicates <- REA_duplicates[source =="REA_duplicate", c("RGC","District","note","geometry")]

# --> Separate geometry values
REA_duplicates[,xcoord := lapply(geometry,`[[`,1)]
REA_duplicates[,ycoord := lapply(geometry,`[[`,2)]
REA_duplicates <- REA_duplicates[, geometry := NULL ]

# --> Add updated values
REA_duplicates[note != "yes" & note != "same", xcoord := as.numeric(strsplit(as.character(note), ",")[[1]][1]), by = RGC]
REA_duplicates[note != "yes" & note != "same", ycoord := as.numeric(strsplit(as.character(note), ",")[[1]][2]), by = RGC]
REA_duplicates[RGC == "Musungu", c("xcoord","ycoord") := .(NA,NA)]
REA_duplicates <- REA_duplicates[, note := NULL ]



# G. Merge
rgc_list2 <- merge(rgc_list2, REA_duplicates, by = c("RGC","District"), all = TRUE)

# -> Blend added data
rgc_list2 <- rgc_list2[source == "REA_duplicate", `X Coordinate`:= xcoord]
rgc_list2 <- rgc_list2[source == "REA_duplicate", `Y Coordinate`:= ycoord]
rgc_list2 <- rgc_list2[, xcoord := NULL][, ycoord := NULL]


# ->SAVE
fwrite(rgc_list2, "/Users/hassanemeite/Dropbox/RA Hassane/RGC_list_allcoords.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)
rm(REA_duplicates)








#*************************************************************************************************************#
#*********************           NEW RGC LIST: COMPARISON WITH LIST 1                   **********************#
#*************************************************************************************************************#

# Clear console with control + L
rm(list=ls())
setwd("/Users/hassanemeite/Documents/To Phd:Masters/Zambia - Rural Electrification Collaborative Research project")


#*********  1.Install & Load Packages
require(zoo)
require(haven)
require(data.table)


#******************************* 2.Quick comparison with new list
rgc_list<- fread("RGC_list.csv")
rgc_list[,c("V11","V12","V13","V14") := .(NULL,NULL,NULL,NULL)]
rgc_list2 <- fread("RGC_list_new.csv")
rgc_list2[,c("V11") :=NULL] # Remove columns
setkey(rgc_list2,Ranking) # Order rows


# Create list for comparison
colnames(rgc_list2) = paste0('new_',names(rgc_list2))
comp_list <- cbind(rgc_list,rgc_list2)

# Test s
comp_list[Ranking==new_Ranking, .N]
comp_list[RGC==new_RGC, .N]


# What I notice are the following:
# 1. Both lists have the same number of observations (1217) and variables (10)
# 2. There is a one to one match between observations from both lists
# 3. 31 observations on the new list have slightly different names, as if they are corrected versions of the ones in the first list. You will find a csv with those observations attached.
check <- comp_list[RGC != new_RGC]
fwrite(check, "new_names_RGC.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)

# 4. Do we have more coordinates? 
# We have coordinates for 541 observations in the the first list whereas we have coordinates for 1037 obervations in the new 
comp_list[ is.na(`X Coordinate`) == FALSE, .N]
comp_list[ is.na(`new_X Coordinate`) == FALSE, .N] # neith are the empty cells; comp_list[ `new_X Coordinate` == "", .N] -> 0
# 5. Are the coordinates for the RGCs that have coordinates in both files identical?
check<-comp_list[ is.na(`new_X Coordinate`) == FALSE]
# First of all it is wroth noticing that the 1037 observations with coordinates in the new list comprise the 541 observations with coordinates from the initial list.
check[ is.na(`X Coordinate`) == FALSE, .N]
# Secondly, all the 541 obseravtions in the new list that already appear in the initial have the same coordinates. 
check2 <- check[ is.na(`X Coordinate`) == FALSE]
check2[`X Coordinate`==`new_X Coordinate` & `Y Coordinate`==`new_Y Coordinate`, .N]
check2 <- check2[`X Coordinate`!=`new_X Coordinate` | `Y Coordinate`!=`new_Y Coordinate`]
# 6. How many are we still missing? 
# We are still missing coordinates for 180 observations.
comp_list[ is.na(`new_X Coordinate`) == TRUE, .N]



