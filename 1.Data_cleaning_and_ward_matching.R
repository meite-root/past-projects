#**********************************************************************************************#
#********************* SETUP:   Clean workspace & set directory          **********************#
#**********************************************************************************************#

#*********  0. Clear console with control + L
rm(list=ls())
setwd("/Users/hassanemeite/Documents/To Phd:Masters/Zambia - Rural Electrification Collaborative Research project")

#*********  1. Install & Load Packages
#install.packages("zoo")
#install.packages("haven")
#install.packages("data.table")
#install.packages("RecordLinkage")

# R Markdown
#install.packages("rmarkdown")
#install.packages("knitr")
# install.packages("htmltools")





#*************************************************************************************************************************************#
#********************* TASK 1:   DATA CLEANING: RECOVER WARD INFO & IDENTIFY SCHOOLS WITH UNIQUE WARDS          **********************#
#*************************************************************************************************************************************#

#*********  1. Load Packages
require(haven)
require(data.table)
require(zoo)

# ********  2. Load orignial DTA file 
schools <- read_dta("school_electricity.dta")
#convert existing objects to a data.table using setDT() (for data.frames and lists)
schools_dt <- setDT(schools)
# Check Total number of observations
schools_dt[, .N]
# Replace all empty spaces in the ward column by “NA”
schools_dt[ward=="", ward := NA]
# Check number of “NA” cells in ward column : 13823
schools_dt[is.na(ward), .N]



# ********  3. Drop unnecessary columns 
schools_relevant<- schools_dt[ , c("run_agency", "nstudents", "nteachers", "grade_range_to_st", "grade_range_from_st", "schooltype_clean", "district_map", "school_lvl") := NULL]

# ********  4. Drop observations with no school name
schools_relevant<- schools_relevant[school_name != ""] 

# ******** 5. Recover Ward information
setkey(schools_relevant, school_num, year) #--> Sorts schools_relevant data in school_num, then year

#Take the value from an earlier year (say 2015) and copy that over to the next year
schools_relevant[, ward_fill := na.locf(ward, na.rm = FALSE), school_num]

#Take the value from an later year (say 2015) and copy that over to the earlier year
schools_relevant[, ward_fill2 := na.locf(ward, na.rm = FALSE, fromLast =TRUE), school_num]

#Fill the original ward column with recovered values
schools_relevant[is.na(ward), ward := ward_fill]
schools_relevant[is.na(ward), ward := ward_fill2]

# Delete additional columns
schools_relevant[, c("ward_fill", "ward_fill2") := NULL]


#******** 6. Identify Schools with non Unique wards
schools_relevant[,wards_count :=.N, by=.(school_num,ward)] # for each schoolnum/ward pair, indicate total number of instances
schools_relevant[,obs_count :=.N, by=.(school_num)] # for each schoolnum , indicate total number of instances
schools_relevant[,unique_ward := (wards_count/obs_count)==1, by=school_num] # for each schoolnum, divide wardscount on obscount.
#It should be 1 if each schoolnum has only one corresponding ward for each for its instances

schools_relevant[,c("wards_count","obs_count") :=NULL] # Remove columns



# ******** 6. CHECKS
#* Check number of “NA” cells in ward column : 8366  | Create separate table with observations with missing ward info
schools_relevant[is.na(ward), .N]
schools_no_ward_info <- schools_relevant[is.na(ward)]

#* Check number of schools with inconsistent wards 8551  | Create separate table with observations with missing ward info
schools_relevant[unique_ward==FALSE, .N]
schools_inconsistent_wards <- schools_relevant[unique_ward==FALSE]

# ******** 7. SAVE (for spatial join)
fwrite(schools_relevant, "zambia_schools.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)









#*****************************************************************************************************#
#*************          TASK 2:      WARDS MATCHING  & ASSESSING                  ********************#
#*****************************************************************************************************#



# 1.  ADJUSTING WARDS MAP TO 2010 DISTRICT CENSUS MAP  ****************************************************************************************************************************************#


#*********  0.Clean Workspace and set directory & Load Packages

# Clear console with control + L
rm(list=ls())
setwd("/Users/hassanemeite/Documents/To Phd:Masters/Zambia - Rural Electrification Collaborative Research project")


# 1.0 For using data.table syntax
require(data.table)

# 1.1 Basic packages necessary for manipulating maps/simple features
library("sf")
library("sp")
library("dplyr") # For relocate() feature

# 1.2  For loading geometries with OGR
library(rgdal)  

# 1.3 For loading .geojson files
library(geojsonsf)
library(jsonlite)

# 1.4 For comparing words
require(RecordLinkage)



#*********  1. LOAD RELEVANT FILES 



# a. Zambia Wards  ************************************************

zambia_wards.sf <- readOGR("Zambia_Wards-2010-Census/", "Fixed_geometries_Zambia_Wards_2014t") 
#--> Next the shapefile has to be converted to a sf for use in ggplot2; 
zambia_wards.sf <- st_as_sf(zambia_wards.sf, coords = c("long", "lat"), crs = 4326, agr = "constant")
# ---> RETRANSFORM COORDINATE SYSTEM TO WGS84, which is the CRS code #4326
zambia_wards.sf = st_transform(zambia_wards.sf, 4326)  # Otherwise it does not overlap

# b. Zambia districts  ************************************************
zambia_districts.sf <- readOGR("Matching districts/population_census_2010/", "geo2_zm2010")
zambia_districts.sf <- st_as_sf(zambia_districts.sf, coords = c("long", "lat"), crs = 4326, agr = "constant")
zambia_districts.sf = st_transform(zambia_districts.sf, 4326)



#******************* PREPARING WARDS FILE FOR QGIS ADJUSTMENT


#--->  SPATIAL JOIN
spatial_join = st_intersection(zambia_wards.sf,zambia_districts.sf)
spatial_join <-  setDT(spatial_join) # To data.table
mismatches.sf <- spatial_join[ADMIN_NAME != DISTRICTNA]


#---> REDUCE TO SINGLE OBSERVATIONS
mismatches.sf[, latest := max(IPUM2010), by= OBJECTID]
mismatches.sf <- mismatches.sf[IPUM2010==latest]
setkey(mismatches.sf, OBJECTID)

#---> MAKE A LIST OF CORRESPONDING OBJECT IDs
mismatchs <- list() 
for (i in 1:nrow(mismatches.sf)) {
  mismatchs <- append (mismatchs, mismatches.sf[i,OBJECTID[[1]]])
}
rm(mismatches.sf)

#---> EXTRACT THOSE FROM zambia_wards file 
zambia_wards.sf <-  setDT(zambia_wards.sf) # To data.table

zambia_wards.sf[, mismatch := "No"]
zambia_wards.sf[, district_harm := "same"]
zambia_wards.sf <- zambia_wards.sf %>% relocate(district_harm, .after=DISTRICTNA)
zambia_wards.sf <- zambia_wards.sf %>% relocate(mismatch, .after=district_harm)

#-> change mismatch to "Yes" if OBJECTID appears in list
for (i in 1:length(mismatchs)) {
  zambia_wards.sf[OBJECTID == mismatchs[[i]], mismatch := "Yes"]
}
zambia_wards.sf[mismatch == "Yes", district_harm := "diff"]
rm(i)

#--> save to geojson thanks to the sf package
# zambia_wards.sf <- zambia_wards.sf[mismatch == "Yes"]
zambia_wards.sf <- st_as_sf(zambia_wards.sf, crs = 4326, agr = "constant")
st_write(zambia_wards.sf, "Zambia_Wards-2010-Census/mismatches.geojson")



#*******************  QGIS ADJUSTMENT
#** Manually check Wards map against districts map to allocate wards to disricts accordingly **#


#******************* AFTER QGIS ADJUSTMENT

#---> LOAD EDITED FILE 
zambia_edited_wards.sf <- geojsonsf::geojson_sf("Zambia_Wards-2010-Census/mismatches_fixed.geojson") # Load geojson to sf
zambia_edited_wards.sf <-  setDT(zambia_edited_wards.sf) # To data.table

#---> ADD EDITED FILE DATA TO ZAMBIA WARDS FILE 
zambia_wards.sf <-  setDT(zambia_wards.sf) # To data.table

#a.Make a list of the harmonized names
districts_harm_list <- list() 
for (i in 1:length(mismatchs)) {
    districts_harm_list <- append(districts_harm_list, zambia_edited_wards.sf[i, district_harm[[1]]]) 
}
#b.Append harmonized names to zambia_wards
for (i in 1:length(mismatchs)) {
  zambia_wards.sf[OBJECTID == mismatchs[[i]] & mismatch== "Yes", district_harm := districts_harm_list [[i]]]
}
#c.Update zambia_wards's district_harm with names of non-mismatched districts
zambia_wards.sf[mismatch== "No", district_harm := DISTRICTNA]

#---> RECONVERT TO SF AND SAVE
zambia_wards.sf <- st_as_sf(zambia_wards.sf, crs = 4326, agr = "constant")
st_write(zambia_wards.sf, "Zambia_Wards-2010-Census/Fixed_names_and_geometries_Zambia_Wards_2014t.prj.geojson") 
rm(mismatchs,i,districts_harm_list,zambia_edited_wards.sf)



#******************* FIXING WARD OVERLAP ISSUES **ON QGIS**  
# SAVE to: --> "Zambia_Wards-2010-Census/Fixed_names_and_geometries_Zambia_Wards_2014t.prj_fixedgeom.geojson"


#******************* CHECKS



#-> 1. District list for both zambia_districts & zambia_wards
zambia_districts.dt <- setDT(zambia_districts.sf) 
zambia_districts.dt[,count :=1]
zambia_wards.dt <- setDT(zambia_wards.sf) 
zambia_wards.dt[,count :=1]
# -> Summarize nuumber of observations by district_emis (from school data)
districts_census_districts <- zambia_districts.dt[, (number_obs = sum(count)), by=ADMIN_NAME]
setkey(districts_census_districts,ADMIN_NAME)
# -> Summarize number of observations by ADMIN_NAME (from map)
districts_census_wards <- zambia_wards.dt[, (number_obs = sum(count)), by=district_harm]
setkey(districts_census_wards,district_harm)
# -> Merge
districts_compare <- data.table(districts_census_districts,districts_census_wards)
rm(districts_census_districts,districts_census_wards,zambia_districts.dt,zambia_wards.dt)

# Delete
rm(districts_compare)


#-> 2. Maps

#0.PREPARE FILES

zambia_wards.sf <- st_as_sf(zambia_wards.sf, crs = 4326, agr = "constant")
zambia_districts.sf <- st_as_sf(zambia_districts.sf, crs = 4326, agr = "constant")

library("ggplot2")
library("ggspatial")
library("RColorBrewer") # display.brewer.all
library("colorRamps") #install.packages("colorRamps")

#Expand palette
nb.cols=74
plotwidth = 12
plotheight = 9.61
plotunit = "in"
#Expand palette
mycolors <- colorRampPalette(brewer.pal(12, "Paired"))(nb.cols)
# Names
dist_labels <- cbind(zambia_districts.sf, st_coordinates(st_centroid(zambia_districts.sf$geometry)))





#1.PLOT CENSUS_DISTRICTS
ggplot(data = zambia_districts.sf) + # Map to be stored in popinfo2020plot
  # a. Colorfill
  geom_sf(color = 'gray58', aes(fill = ADMIN_NAME), size = .2) +
  scale_fill_manual(values = mycolors) +
  #scale_fill_brewer(palette = "Paired") +
  theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), panel.background = element_rect(fill = "aliceblue"))  +
  
  # c. Labels
  geom_text(data= dist_labels,aes(x=X, y=Y, label=ADMIN_NAME), color = "black", fontface = "italic", size = 2, check_overlap = FALSE) +
  
  # e.Arrow & Scale & Legend
  annotation_scale(location = "br", width_hint = 0.25) +
  annotation_north_arrow(location = "br", which_north = "true", pad_x = unit(0.75, "in"), pad_y = unit(0.5, "in"), style = north_arrow_fancy_orienteering) +
  theme(legend.position = c(0.05, 0.05), legend.justification = c(0, 0)) +   # Use legend.position to manually position legend
  theme(legend.position = "none") #-> Remove legend

ggsave("CENSUSU_DISTRICTS.pdf", device = "pdf", width = plotwidth, height = plotheight, unit = plotunit)




#2.PLOT CENSUS_WARDS
ggplot(data = zambia_wards.sf) + # Map to be stored in popinfo2020plot
  # a. Colorfill
  geom_sf(color = 'gray58', aes(fill = district_harm), size = .2) +
  scale_fill_manual(values = mycolors) +
  #scale_fill_brewer(palette = "Paired") +
  theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), panel.background = element_rect(fill = "aliceblue"))  +
  
  # c. Labels
  geom_text(data= dist_labels,aes(x=X, y=Y, label=ADMIN_NAME), color = "black", fontface = "italic", size = 2, check_overlap = FALSE) +
  
  # e.Arrow & Scale & Legend
  annotation_scale(location = "br", width_hint = 0.25) +
  annotation_north_arrow(location = "br", which_north = "true", pad_x = unit(0.75, "in"), pad_y = unit(0.5, "in"), style = north_arrow_fancy_orienteering) +
  theme(legend.position = c(0.05, 0.05), legend.justification = c(0, 0)) +   # Use legend.position to manually position legend
  theme(legend.position = "none") #-> Remove legend

ggsave("CENSUS_WARDS.pdf", device = "pdf", width = plotwidth, height = plotheight, unit = plotunit)


#3.PLOT CENSUS_WARDS_BEFORE
ggplot(data = zambia_wards.sf) + # Map to be stored in popinfo2020plot
  # a. Colorfill
  geom_sf(color = 'gray58', aes(fill = DISTRICTNA), size = .2) +
  scale_fill_manual(values = colorRampPalette(brewer.pal(12, "Paired"))(87)) +
  #scale_fill_brewer(palette = "Paired") +
  theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), panel.background = element_rect(fill = "aliceblue"))  +
  
  # c. Labels
  #geom_text(data= dist_labels,aes(x=X, y=Y, label=ADMIN_NAME), color = "black", fontface = "italic", size = 2, check_overlap = FALSE) +
  
  # e.Arrow & Scale & Legend
  annotation_scale(location = "br", width_hint = 0.25) +
  annotation_north_arrow(location = "br", which_north = "true", pad_x = unit(0.75, "in"), pad_y = unit(0.5, "in"), style = north_arrow_fancy_orienteering) +
  theme(legend.position = c(0.05, 0.05), legend.justification = c(0, 0)) +   # Use legend.position to manually position legend
  theme(legend.position = "none") #-> Remove legend

ggsave("CENSUS_WARDS_NOEDIT.pdf", device = "pdf", width = plotwidth, height = plotheight, unit = plotunit)


# DELETE TABLES
rm(dist_labels)
rm(mycolors,nb.cols,plotheight,plotunit,plotwidth)













# 2. ADJUSTING SCHOOL DATA TO 2010 DISTRICT CENSUS MAP  *****************************************************************************************************************************************

#*********  0.Clean Workspace and set directory & Load Packages

# Clear console with control + L
rm(list=ls())
setwd("/Users/hassanemeite/Documents/To Phd:Masters/Zambia - Rural Electrification Collaborative Research project")


# 1.0
require(data.table)


#*********  1. LOAD RELEVANT FILES 

# a. schools ************************************************

#---> LOAD
schools<- fread("zambia_schools.csv")

#******** 1. SET DISTRICTS BACK TO IPUMS 2010 DISTRICT NAMES

schools[, district_ipums := "NA"] #Set new column for 2010 districts info
setcolorder(schools, c("school_num","school_name","year","rural","district_emis","district_ipums","source_coordinates","lat","lon","ward","powersource","unique_ward"))

schools[district_emis=="Sikongo", district_ipums := "Kalabo"]
schools[district_emis=="Mitete", district_ipums := "Lukulu"]
schools[district_emis=="Manyinga", district_ipums := "Kabompo"]
schools[district_emis=="Limulunga", district_ipums := "Mongu"]
schools[district_emis=="Nalolo", district_ipums := "Senanga"]
schools[district_emis=="Sioma", district_ipums := "Shang'ombo"]
schools[district_emis=="Mwandi", district_ipums := "Sesheke"]
schools[district_emis=="Mulobezi", district_ipums := "Sesheke"]
schools[district_emis=="Nkeyema", district_ipums := "Kaoma"]
schools[district_emis=="Luampa", district_ipums := "Kaoma"]
schools[district_emis=="Pemba", district_ipums := "Choma"]
schools[district_emis=="Chirundu", district_ipums := "Siavonga"]
schools[district_emis=="Chikankata", district_ipums := "Mazabuka"]
schools[district_emis=="Chisamba", district_ipums := "Chibombo"]
schools[district_emis=="Luano", district_ipums := "Mkushi"]
schools[district_emis=="Ngabwe", district_ipums := "Kapiri Mposhi"]
schools[district_emis=="Mwembeshi", district_ipums := "Mumbwa"]
schools[district_emis=="Chilanga", district_ipums := "Kafue"]
schools[district_emis=="Rufunsa", district_ipums := "Chongwe"]
schools[district_emis=="Sinda", district_ipums := "Katete"]
schools[district_emis=="Vubwi", district_ipums := "Chadiza"]
schools[district_emis=="Lunga", district_ipums := "Samfya"]
schools[district_emis=="Chembe", district_ipums := "Mansa"]
schools[district_emis=="Chipili", district_ipums := "Mwense"]
schools[district_emis=="Shiwangandu", district_ipums := "Chinsali"]
schools[district_emis=="Mwansabombwe", district_ipums := "Kawambwa"]
schools[district_emis=="Nsama", district_ipums := "Kaputa"]
schools[district_emis=="Chiengi", district_ipums := "Chienge"]
schools[district_emis=="Chitambo", district_ipums := "Serenje"]
schools[district_emis=="Shangombo", district_ipums := "Shang'ombo"]
schools[district_emis=="Shibuyunji", district_ipums := "Mumbwa"]
schools[district_emis=="Zimba", district_ipums := "Kalomo"]
schools[district_emis=="Mufumbwe", district_ipums := "Mufumbwe (Chizera)"]

schools[district_ipums != "NA", district_emis := district_ipums]
schools[, district_ipums := NULL]


fwrite(schools, "zambia_schools_adjusted.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)
rm(schools)













# 3. MATCHING EXERCISE: MAPPING SCHOOLS AGAINST WARDS MAP (SPATIAL JOIN) *****************************************************************************************************************************************

#*********  0.Clean Workspace and set directory & Load Packages

# Clear console with control + L
rm(list=ls())
setwd("/Users/hassanemeite/Documents/To Phd:Masters/Zambia - Rural Electrification Collaborative Research project")


# 1.0
require(data.table)

# 1.1 We start by loading the basic packages necessary for all maps, i.e. ggplot2 and sf. 
library("sf")
library("sp")
library("dplyr") # For relocate() feature

# 1.2
library(rgdal)     # R wrapper around GDAL/OGR

# 1.3 geojson
library(geojsonsf)
library(jsonlite)

# 1.4 For comparing words
require(RecordLinkage)


  
#*********  1. LOAD RELEVANT FILES 
  
# a. schools ************************************************

#---> LOAD
schools<- fread("zambia_schools_adjusted.csv")
# schools<- fread("/Users/hassanemeite/Dropbox/Zambia_Infrastructure_Complementarity/Build/Source/EMIS-Schools/zambia_schools_adjusted.csv")

# Total Obs: 129743
# With coordinates: 77648 (59.8%)
# Without: 52095 (40.2%)
  
#---> TRANSFORM DATATABLE TO SIMPLE FEATURE
schools_nocoord <- schools[ !is.na(lat)==FALSE]   
schools <- schools[ is.na(lat)==FALSE]   
schools.sf <- st_as_sf(schools, coords = c("lon", "lat"), crs = 4326, agr = "constant") #  WGS84, which is the CRS code #4326)
rm(schools_nocoord,schools)
  
  # b. Zambia Wards  ************************************************
  
  
  zambia_wards.sf <- geojsonsf::geojson_sf("Zambia_Wards-2010-Census/Fixed_names_and_geometries_Zambia_Wards_2014t.prj_fixedgeom.geojson") # Load geojson to sf
  
  # ---> RETRANSFORM COORDINATE SYSTEM TO WGS84, which is the CRS code #4326
  zambia_wards.sf = st_transform(zambia_wards.sf, 4326)  # Otherwise it does not overlap
  
  
  
  
#  *********  2. SPATIAL JOIN
  spatial_join = st_intersection(schools.sf, zambia_wards.sf)
  spatial_join <- setDT(spatial_join) # To data.table
  setkey(spatial_join, school_num,year)
  rm(schools.sf)
  
  #---> CHECK FOR DUPLICATES
  # duplicates_spatial_join <- spatial_join[duplicated(spatial_join,by = key(spatial_join))==TRUE]
  # duplicates_spatial_join <- st_as_sf(duplicates_spatial_join, crs = 4326, agr = "constant")
  # st_write(duplicates_spatial_join, "duplicates_Zambia_Wards-2010-Census.geojson") 
  # rm(duplicates_spatial_join)
  
  
  #*********  3. RENAME VARIABLES FOR BETTER CLARITY
  #a. ---> Rename WARD_NAME, edit both ward variables contents to lowercase & drop unnecessary columns
  
  spatial_join[,count :=1]
  spatial_join[,ward_school := ward][, ward := NULL]
  spatial_join[,ward_census := WARD_NAME][, WARD_NAME := NULL]
  spatial_join[,ward_school := tolower(ward_school)][,ward_census := tolower(ward_census)]
  
  
  #b. ---> Rename DISTRICTNA, edit both ward variables contents to lowercase & drop unnecessary columns
  spatial_join[,district_census := DISTRICTNA][, DISTRICTNA := NULL]
  spatial_join[,district_school := district_emis][, district_emis := NULL]
  spatial_join[,district_school := tolower(district_school)][,district_census := tolower(district_census)][,district_harm := tolower(district_harm)]
  
  
  #*********  4. ASSESS WHETHER WARD NAMES and DISTRICT NAMES ARE THE SAME IN BOTH SCHOOL DATA AND THE ZAMBIA MAP
  
  #a. --->  Assign Similarity scores for WARDS based on string comparison in R (edit distance)
  
  #* New column that concatenates both ward and ward_census info into one string (to ease the use of the levenshteinSim fonction)
  spatial_join[, wards_string := paste (ward_school,ward_census, sep=" ; ")] 
  #* For each schoolnum, Assign Similarity score in a "wards_similar" column by comparing both original and mapped ward info
  spatial_join[, wards_similar := levenshteinSim(strsplit(wards_string, " ; ")[[1]][1],strsplit(wards_string, " ; ")[[1]][2]), by =school_num]
  #* Remove wards_string column
  spatial_join[, wards_string := NULL]
  #* Reorder columns
  setcolorder(spatial_join, c("school_num","school_name","year","rural","district_school","source_coordinates","ward_school","ward_census","wards_similar","powersource","unique_ward","ID","PROV_CODE","PROVINCENA","DISTRICT_C","district_census","district_harm","CONST_CODE","WARD_CODE","perimeter","Shape_Leng","Shape_Area","Pop2010","geometry") )
  

  #b. --->  Assign Similarity scores for DISTRICTS based on string comparison in R (edit distance)
  
  #* New column that concatenates both district and district_census info into one string (to ease the use of the levenshteinSim fonction)
  #spatial_join[, districts_string := paste (district_school,district_census, sep=" ; ")] 
  spatial_join[, districts_string := paste (district_school,district_harm, sep=" ; ")] 
  #* For each schoolnum, Assign Similarity score in a "districts_similar_harm" column by comparing both original and mapped district info
  spatial_join[, districts_similar_harm := levenshteinSim(strsplit(districts_string, " ; ")[[1]][1],strsplit(districts_string, " ; ")[[1]][2]), by =school_num]
  #* Remove districts_string column
  spatial_join[, districts_string := NULL]
  #* Reorder columns
  setcolorder(spatial_join, c("school_num","school_name","year","rural","source_coordinates","ward_school","ward_census","wards_similar","district_school","district_census","district_harm","districts_similar_harm","powersource","unique_ward","ID","PROV_CODE","PROVINCENA","DISTRICT_C","CONST_CODE","WARD_CODE","perimeter","Shape_Leng","Shape_Area","Pop2010","geometry") )
  
  
  
  
#d. ---> Tests & results 
  
spatial_join[,.N]
# total Number of observations in the spatial_join data table: 

spatial_join[districts_similar_harm== 1, .N]
# Number of observations falling in a district with the exact same name it indicated prior to the spatial join: 70,712

spatial_join[between(districts_similar_harm, 0.6, 0.99)==TRUE, .N]
# Number of observations falling in a district with a name similar to the one it indicated prior to the spatial join (mismatches due to typos): 0


# ----> EDITS ****************************************************************************************************


#********************* CASE 1: same district, Same ward
spatial_join[districts_similar_harm== 1 & wards_similar== 1, .N]
# Number of obs with same district & wards names: 35,097



#********************* CASE 2: same district, similar ward

# ----> TEST
spatial_join[districts_similar_harm== 1 & between(wards_similar, 0.6, 0.99)==TRUE, .N]
# number of obs: 6,787 

# ----> ADJUST
# Setup Compass variable
spatial_join[, mismatch_ward := "no"]
spatial_join[wards_similar != 1 , mismatch_ward := "yes"]


# Generate lines of code for a quick adjustment 
#-> Create table with mismatches
# mismatches <- spatial_join[districts_similar_harm== 1 & between(wards_similar, 0.6, 0.99)==TRUE]
# setkey(mismatches, districts_similar_harm, wards_similar)
# #-> Create table for code
# code <- mismatches[, (rural = sum(rural)), by= .(ward_school,ward_census,wards_similar)]
# code[, code_string := paste ("spatial_join[mismatch_ward == `yes` & ward_school==`",ward_school,"` & ward_census = `",ward_census,"`, ward_harm := `",ward_census,"`]", sep="")]
# setkey(code, wards_similar)
# fwrite(code, "code.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)
# rm(code)

# Add ward_harm to spatial join and edit accordingly
spatial_join[, ward_harm := "NA"] #Set new column for 2010 districts info  
spatial_join <- spatial_join %>% relocate(ward_harm, .after=ward_census)

#1 - Initialize
spatial_join[mismatch_ward == "no", ward_harm := ward_school]

#2 - Change where edits are needed
 
#spatial_join[mismatch_ward == "yes" & ward_school=="simu" & ward_census == "sioma", ward_harm := "sioma"]
#spatial_join[mismatch_ward == "yes" & ward_school=="sikabange" & ward_census == "sioma", ward_harm := "sioma"]
#spatial_join[mismatch_ward == "yes" & ward_school=="chilanga" & ward_census == "chilongolo", ward_harm := "chilongolo"]
#spatial_join[mismatch_ward == "yes" & ward_school=="mulungushi" & ward_census == "mpulungu", ward_harm := "mpulungu"]
#spatial_join[mismatch_ward == "yes" & ward_school=="nkandambwe" & ward_census == "nangombe", ward_harm := "nangombe"]
#spatial_join[mismatch_ward == "yes" & ward_school=="chitanda" & ward_census == "chisamba", ward_harm := "chisamba"]
#spatial_join[mismatch_ward == "yes" & ward_school=="masanga" & ward_census == "chisanga", ward_harm := "chisanga"]
#spatial_join[mismatch_ward == "yes" & ward_school=="mpulungu" & ward_census == "mapungu", ward_harm := "mapungu"]
#spatial_join[mismatch_ward == "yes" & ward_school=="kafubu" & ward_census == "kafue", ward_harm := "kafue"]
#spatial_join[mismatch_ward == "yes" & ward_school=="nyaala" & ward_census == "nyawa", ward_harm := "nyawa"]
#spatial_join[mismatch_ward == "yes" & ward_school=="miulwe" & ward_census == "mulwa", ward_harm := "mulwa"]
#spatial_join[mismatch_ward == "yes" & ward_school=="sipuma" & ward_census == "sioma", ward_harm := "sioma"]
# spatial_join[mismatch_ward == "yes" & ward_school=="luumbo" & ward_census == "fumbo", ward_harm := "fumbo"]
# spatial_join[mismatch_ward == "yes" & ward_school=="chikobo" & ward_census == "chikola", ward_harm := "chikola"]
# spatial_join[mismatch_ward == "yes" & ward_school=="kabwata" & ward_census == "kamwala", ward_harm := "kamwala"]
# spatial_join[mismatch_ward == "yes" & ward_school=="kasansa" & ward_census == "kasaba", ward_harm := "kasaba"]
# spatial_join[mismatch_ward == "yes" & ward_school=="kapamba" & ward_census == "kasaba", ward_harm := "kasaba"]
# spatial_join[mismatch_ward == "yes" & ward_school=="chawama" & ward_census == "chinama", ward_harm := "chinama"]
# spatial_join[mismatch_ward == "yes" & ward_school=="lubala" & ward_census == "lubanda", ward_harm := "lubanda"]
# spatial_join[mismatch_ward == "yes" & ward_school=="maiteneke" & ward_census == "chikola", ward_harm := "chikola"]

spatial_join[mismatch_ward == "yes" & ward_school=="chilongolo" & ward_census == "chilongolo", ward_harm := "chilongolo"]
spatial_join[mismatch_ward == "yes" & ward_school=="imatongo" & ward_census == "imatanda", ward_harm := "imatanda"]
spatial_join[mismatch_ward == "yes" & ward_school=="ilambo" & ward_census == "ilombe", ward_harm := "ilombe"]
spatial_join[mismatch_ward == "yes" & ward_school=="nkanga" & ward_census == "nsenga", ward_harm := "nsenga"]
spatial_join[mismatch_ward == "yes" & ward_school=="luche" & ward_census == "nsenga", ward_harm := "nsenga"]
spatial_join[mismatch_ward == "yes" & ward_school=="munwakubili" & ward_census == "mwanuakabili", ward_harm := "mwanuakabili"]
spatial_join[mismatch_ward == "yes" & ward_school=="kapembwa" & ward_census == "kamphemba", ward_harm := "kamphemba"]
spatial_join[mismatch_ward == "yes" & ward_school=="lumezi" & ward_census == "lunzi", ward_harm := "lunzi"]
spatial_join[mismatch_ward == "yes" & ward_school=="kapita" & ward_census == "katipa", ward_harm := "katipa"]
spatial_join[mismatch_ward == "yes" & ward_school=="katokota" & ward_census == "kota kota", ward_harm := "kota kota"]
spatial_join[mismatch_ward == "yes" & ward_school=="chililamanyama" & ward_census == "chalimanyana", ward_harm := "chalimanyana"]
spatial_join[mismatch_ward == "yes" & ward_school=="naluyau" & ward_census == "naluywa", ward_harm := "naluywa"]
spatial_join[mismatch_ward == "yes" & ward_school=="itumbwe" & ward_census == "itumbi", ward_harm := "itumbi"]
spatial_join[mismatch_ward == "yes" & ward_school=="kabungo" & ward_census == "kabundi", ward_harm := "kabundi"]
spatial_join[mismatch_ward == "yes" & ward_school=="peb-kabesa" & ward_census == "pabe kabesa", ward_harm := "pabe kabesa"]
spatial_join[mismatch_ward == "yes" & ward_school=="kalengwa" & ward_census == "kalanga", ward_harm := "kalanga"]
spatial_join[mismatch_ward == "yes" & ward_school=="kasonga" & ward_census == "kansonka", ward_harm := "kansonka"]
spatial_join[mismatch_ward == "yes" & ward_school=="kansoka" & ward_census == "kansonka", ward_harm := "kansonka"]
spatial_join[mismatch_ward == "yes" & ward_school=="nakasa" & ward_census == "nakasaka", ward_harm := "nakasaka"]
spatial_join[mismatch_ward == "yes" & ward_school=="choogo east" & ward_census == "choongo west", ward_harm := "choongo west"]
spatial_join[mismatch_ward == "yes" & ward_school=="sikoonga" & ward_census == "sikongo", ward_harm := "sikongo"]
spatial_join[mismatch_ward == "yes" & ward_school=="muchinga" & ward_census == "ichinga", ward_harm := "ichinga"]
spatial_join[mismatch_ward == "yes" & ward_school=="mng'omba" & ward_census == "mngo'mba", ward_harm := "mngo'mba"]
spatial_join[mismatch_ward == "yes" & ward_school=="lubi" & ward_census == "luli", ward_harm := "luli"]
spatial_join[mismatch_ward == "yes" & ward_school=="mumbeji" & ward_census == "mumbezhi", ward_harm := "mumbezhi"]
spatial_join[mismatch_ward == "yes" & ward_school=="g. chifwembe" & ward_census == "chifwembe", ward_harm := "chifwembe"]
spatial_join[mismatch_ward == "yes" & ward_school=="chingola" & ward_census == "chikola", ward_harm := "chikola"]
spatial_join[mismatch_ward == "yes" & ward_school=="ng'ombe-ilede" & ward_census == "ngombe ilende", ward_harm := "ngombe ilende"]
spatial_join[mismatch_ward == "yes" & ward_school=="masanga" & ward_census == "masaninga", ward_harm := "masaninga"]
spatial_join[mismatch_ward == "yes" & ward_school=="hatontola" & ward_census == "hantotola", ward_harm := "hantotola"]
spatial_join[mismatch_ward == "yes" & ward_school=="mupamadzi" & ward_census == "munpamazi", ward_harm := "munpamazi"]
spatial_join[mismatch_ward == "yes" & ward_school=="sikabange" & ward_census == "sikabenga", ward_harm := "sikabenga"]
spatial_join[mismatch_ward == "yes" & ward_school=="chipandu" & ward_census == "chimpundu", ward_harm := "chimpundu"]
spatial_join[mismatch_ward == "yes" & ward_school=="ben kafupi" & ward_census == "ben kapufi", ward_harm := "ben kapufi"]
spatial_join[mismatch_ward == "yes" & ward_school=="chipembe" & ward_census == "chipembele", ward_harm := "chipembele"]
spatial_join[mismatch_ward == "yes" & ward_school=="nkandambwe" & ward_census == "nkamdabwe", ward_harm := "nkamdabwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="luena" & ward_census == "luela", ward_harm := "luela"]
spatial_join[mismatch_ward == "yes" & ward_school=="mwanza east" & ward_census == "mwanza west", ward_harm := "mwanza west"]
spatial_join[mismatch_ward == "yes" & ward_school=="chipolonge" & ward_census == "chimpolenge", ward_harm := "chimpolenge"]
spatial_join[mismatch_ward == "yes" & ward_school=="kapangulu" & ward_census == "kapangulula", ward_harm := "kapangulula"]
spatial_join[mismatch_ward == "yes" & ward_school=="chikokwelu" & ward_census == "chikonkwelo", ward_harm := "chikonkwelo"]
spatial_join[mismatch_ward == "yes" & ward_school=="mwanza west" & ward_census == "mwanza east", ward_harm := "mwanza east"]
spatial_join[mismatch_ward == "yes" & ward_school=="chibombo-mbalanga" & ward_census == "chivombo mbalango", ward_harm := "chivombo mbalango"]
spatial_join[mismatch_ward == "yes" & ward_school=="ibenge" & ward_census == "ibenga", ward_harm := "ibenga"]
spatial_join[mismatch_ward == "yes" & ward_school=="musofu" & ward_census == "masofu", ward_harm := "masofu"]
spatial_join[mismatch_ward == "yes" & ward_school=="mumbwa" & ward_census == "mumba", ward_harm := "mumba"]
spatial_join[mismatch_ward == "yes" & ward_school=="choongo west" & ward_census == "choongo east", ward_harm := "choongo east"]
spatial_join[mismatch_ward == "yes" & ward_school=="keembe" & ward_census == "keemba", ward_harm := "keemba"]
spatial_join[mismatch_ward == "yes" & ward_school=="mooba" & ward_census == "moomba", ward_harm := "moomba"]
spatial_join[mismatch_ward == "yes" & ward_school=="mayoba" & ward_census == "mayaba", ward_harm := "mayaba"]
spatial_join[mismatch_ward == "yes" & ward_school=="momfwe" & ward_census == "mofwe", ward_harm := "mofwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="itemba" & ward_census == "itembo", ward_harm := "itembo"]
spatial_join[mismatch_ward == "yes" & ward_school=="mpundu" & ward_census == "mpungu", ward_harm := "mpungu"]
spatial_join[mismatch_ward == "yes" & ward_school=="likulu" & ward_census == "lukulu", ward_harm := "lukulu"]
spatial_join[mismatch_ward == "yes" & ward_school=="chumbu" & ward_census == "chumba", ward_harm := "chumba"]
spatial_join[mismatch_ward == "yes" & ward_school=="lwandi" & ward_census == "luandi", ward_harm := "luandi"]
spatial_join[mismatch_ward == "yes" & ward_school=="intala" & ward_census == "itala", ward_harm := "itala"]
spatial_join[mismatch_ward == "yes" & ward_school=="funga" & ward_census == "fungwa", ward_harm := "fungwa"]
spatial_join[mismatch_ward == "yes" & ward_school=="mpande" & ward_census == "mpanda", ward_harm := "mpanda"]
spatial_join[mismatch_ward == "yes" & ward_school=="isunda" & ward_census == "isunga", ward_harm := "isunga"]
spatial_join[mismatch_ward == "yes" & ward_school=="vumbwi" & ward_census == "vubwi", ward_harm := "vubwi"]
spatial_join[mismatch_ward == "yes" & ward_school=="chipapangali" & ward_census == "chipangali", ward_harm := "chipangali"]
spatial_join[mismatch_ward == "yes" & ward_school=="nkhova" & ward_census == "khova", ward_harm := "khova"]
spatial_join[mismatch_ward == "yes" & ward_school=="kapilisanga" & ward_census == "kapirinsanga", ward_harm := "kapirinsanga"]
spatial_join[mismatch_ward == "yes" & ward_school=="nsimo" & ward_census == "nsimbo", ward_harm := "nsimbo"]
spatial_join[mismatch_ward == "yes" & ward_school=="silwe" & ward_census == "siluwe", ward_harm := "siluwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="ng'uma" & ward_census == "nguma", ward_harm := "nguma"]
spatial_join[mismatch_ward == "yes" & ward_school=="kamba" & ward_census == "kambai", ward_harm := "kambai"]
spatial_join[mismatch_ward == "yes" & ward_school=="loanja" & ward_census == "lwanja", ward_harm := "lwanja"]
spatial_join[mismatch_ward == "yes" & ward_school=="nyala" & ward_census == "nyaala", ward_harm := "nyaala"]
spatial_join[mismatch_ward == "yes" & ward_school=="itembi" & ward_census == "itumbi", ward_harm := "itumbi"]
spatial_join[mismatch_ward == "yes" & ward_school=="mandi" & ward_census == "mwandi", ward_harm := "mwandi"]
spatial_join[mismatch_ward == "yes" & ward_school=="chilantambo" & ward_census == "chilalantambo", ward_harm := "chilalantambo"]
spatial_join[mismatch_ward == "yes" & ward_school=="mushitu-wambo" & ward_census == "mushituwamboo", ward_harm := "mushituwamboo"]
spatial_join[mismatch_ward == "yes" & ward_school=="mutundu" & ward_census == "mulundu", ward_harm := "mulundu"]
spatial_join[mismatch_ward == "yes" & ward_school=="murundu" & ward_census == "mulundu", ward_harm := "mulundu"]
spatial_join[mismatch_ward == "yes" & ward_school=="kasemba" & ward_census == "kasempa", ward_harm := "kasempa"]
spatial_join[mismatch_ward == "yes" & ward_school=="mukombo" & ward_census == "mukumbo", ward_harm := "mukumbo"]
spatial_join[mismatch_ward == "yes" & ward_school=="kalwelo" & ward_census == "kalweo", ward_harm := "kalweo"]
spatial_join[mismatch_ward == "yes" & ward_school=="chipaba" & ward_census == "chapaba", ward_harm := "chapaba"]
spatial_join[mismatch_ward == "yes" & ward_school=="upper lusemfwa" & ward_census == "upper lunsefwa", ward_harm := "upper lunsefwa"]
spatial_join[mismatch_ward == "yes" & ward_school=="ngambwe" & ward_census == "ngabwe", ward_harm := "ngabwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="kambule" & ward_census == "kambale", ward_harm := "kambale"]
spatial_join[mismatch_ward == "yes" & ward_school=="malaila" & ward_census == "malala", ward_harm := "malala"]
spatial_join[mismatch_ward == "yes" & ward_school=="mulimya" & ward_census == "mulima", ward_harm := "mulima"]
spatial_join[mismatch_ward == "yes" & ward_school=="mulunda" & ward_census == "mulundu", ward_harm := "mulundu"]
spatial_join[mismatch_ward == "yes" & ward_school=="kabansa" & ward_census == "kabanse", ward_harm := "kabanse"]
spatial_join[mismatch_ward == "yes" & ward_school=="ng'ona" & ward_census == "ngo'ona", ward_harm := "ngo'ona"]
spatial_join[mismatch_ward == "yes" & ward_school=="lumanya" & ward_census == "lumamya", ward_harm := "lumamya"]
spatial_join[mismatch_ward == "yes" & ward_school=="chienge" & ward_census == "chiengi", ward_harm := "chiengi"]
spatial_join[mismatch_ward == "yes" & ward_school=="mununga" & ward_census == "munungu", ward_harm := "munungu"]
spatial_join[mismatch_ward == "yes" & ward_school=="kantete" & ward_census == "katete", ward_harm := "katete"]
spatial_join[mismatch_ward == "yes" & ward_school=="ichingo" & ward_census == "ichinga", ward_harm := "ichinga"]
spatial_join[mismatch_ward == "yes" & ward_school=="ichinga" & ward_census == "ichinga", ward_harm := "ichinga"]
spatial_join[mismatch_ward == "yes" & ward_school=="makumbi" & ward_census == "mukumbi", ward_harm := "mukumbi"]
spatial_join[mismatch_ward == "yes" & ward_school=="kapisha" & ward_census == "lapisha", ward_harm := "lapisha"]
spatial_join[mismatch_ward == "yes" & ward_school=="chibwa" & ward_census == "chimbwa", ward_harm := "chimbwa"]
spatial_join[mismatch_ward == "yes" & ward_school=="khumba" & ward_census == "nkhumba", ward_harm := "nkhumba"]
spatial_join[mismatch_ward == "yes" & ward_school=="ampidzi" & ward_census == "ambidzi", ward_harm := "ambidzi"]
spatial_join[mismatch_ward == "yes" & ward_school=="chisiye" & ward_census == "chisiya", ward_harm := "chisiya"]
spatial_join[mismatch_ward == "yes" & ward_school=="kawaza" & ward_census == "kamwaza", ward_harm := "kamwaza"]
spatial_join[mismatch_ward == "yes" & ward_school=="singizi" & ward_census == "singozi", ward_harm := "singozi"]
spatial_join[mismatch_ward == "yes" & ward_school=="lunyiwu" & ward_census == "lunyiwe", ward_harm := "lunyiwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="kayombu" & ward_census == "kayombo", ward_harm := "kayombo"]
spatial_join[mismatch_ward == "yes" & ward_school=="mukenge" & ward_census == "mukinge", ward_harm := "mukinge"]
spatial_join[mismatch_ward == "yes" & ward_school=="mukandakunda" & ward_census == "mukanda nkunda", ward_harm := "mukanda nkunda"]
spatial_join[mismatch_ward == "yes" & ward_school=="nkeyema" & ward_census == "nkeyama", ward_harm := "nkeyama"]
spatial_join[mismatch_ward == "yes" & ward_school=="lea lui" & ward_census == "lealui", ward_harm := "lealui"]
spatial_join[mismatch_ward == "yes" & ward_school=="linzuma" & ward_census == "lizuma", ward_harm := "lizuma"]
spatial_join[mismatch_ward == "yes" & ward_school=="limwiko" & ward_census == "imwiko", ward_harm := "imwiko"]
spatial_join[mismatch_ward == "yes" & ward_school=="chivweji-kasesi" & ward_census == "chivweti kasesi", ward_harm := "chivweti kasesi"]
spatial_join[mismatch_ward == "yes" & ward_school=="kansoka" & ward_census == "kansonka", ward_harm := "kansonka"]
spatial_join[mismatch_ward == "yes" & ward_school=="kabundi" & ward_census == "kabundia", ward_harm := "kabundia"]
spatial_join[mismatch_ward == "yes" & ward_school=="kamimbia" & ward_census == "kamimbya", ward_harm := "kamimbya"]
spatial_join[mismatch_ward == "yes" & ward_school=="muchinda" & ward_census == "muchinga", ward_harm := "muchinga"]
spatial_join[mismatch_ward == "yes" & ward_school=="ng'answa" & ward_census == "nganswa", ward_harm := "nganswa"]
spatial_join[mismatch_ward == "yes" & ward_school=="mukubwe" & ward_census == "mukumbwe", ward_harm := "mukumbwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="kampumba" & ward_census == "kapumba", ward_harm := "kapumba"]
spatial_join[mismatch_ward == "yes" & ward_school=="simaubi" & ward_census == "simaumbi", ward_harm := "simaumbi"]
spatial_join[mismatch_ward == "yes" & ward_school=="chisangu" & ward_census == "chisanga", ward_harm := "chisanga"]
spatial_join[mismatch_ward == "yes" & ward_school=="konkola" & ward_census == "nkonkola", ward_harm := "nkonkola"]
spatial_join[mismatch_ward == "yes" & ward_school=="simaamba" & ward_census == "simamba", ward_harm := "simamba"]
spatial_join[mismatch_ward == "yes" & ward_school=="muleshi" & ward_census == "mulenshi", ward_harm := "mulenshi"]
spatial_join[mismatch_ward == "yes" & ward_school=="chishela" & ward_census == "chisela", ward_harm := "chisela"]
spatial_join[mismatch_ward == "yes" & ward_school=="manzonde" & ward_census == "mazonde", ward_harm := "mazonde"]
spatial_join[mismatch_ward == "yes" & ward_school=="ngongwe" & ward_census == "ng'ongwe", ward_harm := "ng'ongwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="ongoliwe" & ward_census == "ongolwe", ward_harm := "ongolwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="mnkhnya" & ward_census == "mnkhanya", ward_harm := "mnkhanya"]
spatial_join[mismatch_ward == "yes" & ward_school=="kamakuku" & ward_census == "kamakoku", ward_harm := "kamakoku"]
spatial_join[mismatch_ward == "yes" & ward_school=="lwitadi-lwatembu" & ward_census == "lwitadi lwatembo", ward_harm := "lwitadi lwatembo"]
spatial_join[mismatch_ward == "yes" & ward_school=="lunkunyi" & ward_census == "lukunyi", ward_harm := "lukunyi"]
spatial_join[mismatch_ward == "yes" & ward_school=="lutemwe" & ward_census == "lutembwe", ward_harm := "lutembwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="matondo-nyachika" & ward_census == "matondo nyachikai", ward_harm := "matondo nyachikai"]
spatial_join[mismatch_ward == "yes" & ward_school=="muchishi" & ward_census == "muchinshi", ward_harm := "muchinshi"]
spatial_join[mismatch_ward == "yes" & ward_school=="buntugwa" & ward_census == "buntungwa", ward_harm := "buntungwa"]
spatial_join[mismatch_ward == "yes" & ward_school=="ipusukulo" & ward_census == "ipusukilo", ward_harm := "ipusukilo"]
spatial_join[mismatch_ward == "yes" & ward_school=="chibanga" & ward_census == "chinbanga", ward_harm := "chinbanga"]
spatial_join[mismatch_ward == "yes" & ward_school=="lwanchele" & ward_census == "luanchele", ward_harm := "luanchele"]
spatial_join[mismatch_ward == "yes" & ward_school=="mwebeshi" & ward_census == "mwembeshi", ward_harm := "mwembeshi"]
spatial_join[mismatch_ward == "yes" & ward_school=="kalundana" & ward_census == "kulundana", ward_harm := "kulundana"]
spatial_join[mismatch_ward == "yes" & ward_school=="namianga" & ward_census == "namwianga", ward_harm := "namwianga"]
spatial_join[mismatch_ward == "yes" & ward_school=="kantengwe" & ward_census == "kantengwa", ward_harm := "kantengwa"]
spatial_join[mismatch_ward == "yes" & ward_school=="nang'ombe" & ward_census == "nangombe", ward_harm := "nangombe"]
spatial_join[mismatch_ward == "yes" & ward_school=="chipundu" & ward_census == "chimpundu", ward_harm := "chimpundu"]
spatial_join[mismatch_ward == "yes" & ward_school=="chifungwe" & ward_census == "chibungwe", ward_harm := "chibungwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="msanndile" & ward_census == "msandile", ward_harm := "msandile"]
spatial_join[mismatch_ward == "yes" & ward_school=="vulamkolo" & ward_census == "vulamkoko", ward_harm := "vulamkoko"]
spatial_join[mismatch_ward == "yes" & ward_school=="mnyamanzi" & ward_census == "mnyamazi", ward_harm := "mnyamazi"]
spatial_join[mismatch_ward == "yes" & ward_school=="nakawise" & ward_census == "nyakawise", ward_harm := "nyakawise"]
spatial_join[mismatch_ward == "yes" & ward_school=="sailung'a" & ward_census == "sailunga", ward_harm := "sailunga"]
spatial_join[mismatch_ward == "yes" & ward_school=="kasampula" & ward_census == "kasambula", ward_harm := "kasambula"]
spatial_join[mismatch_ward == "yes" & ward_school=="mundwiji" & ward_census == "mundwinji", ward_harm := "mundwinji"]
spatial_join[mismatch_ward == "yes" & ward_school=="chilenga-chizenzi" & ward_census == "chileng'a chizenzi", ward_harm := "chileng'a chizenzi"]
spatial_join[mismatch_ward == "yes" & ward_school=="limilunga" & ward_census == "limulunga", ward_harm := "limulunga"]
spatial_join[mismatch_ward == "yes" & ward_school=="mashukula" & ward_census == "mushukula", ward_harm := "mushukula"]
spatial_join[mismatch_ward == "yes" & ward_school=="luamuloba" & ward_census == "lwamuloba", ward_harm := "lwamuloba"]
spatial_join[mismatch_ward == "yes" & ward_school=="kashizhi" & ward_census == "kanshizhi", ward_harm := "kanshizhi"]
spatial_join[mismatch_ward == "yes" & ward_school=="kamilenge" & ward_census == "kamilende", ward_harm := "kamilende"]
spatial_join[mismatch_ward == "yes" & ward_school=="chinonwe" & ward_census == "chin'onwe", ward_harm := "chin'onwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="state land" & ward_census == "stateland", ward_harm := "stateland"]
spatial_join[mismatch_ward == "yes" & ward_school=="manchavwa" & ward_census == "manchanvwa", ward_harm := "manchanvwa"]
spatial_join[mismatch_ward == "yes" & ward_school=="nalupembe" & ward_census == "nalumpembe", ward_harm := "nalumpembe"]
spatial_join[mismatch_ward == "yes" & ward_school=="mfwambeshi" & ward_census == "mwambeshi", ward_harm := "mwambeshi"]
spatial_join[mismatch_ward == "yes" & ward_school=="mankangila" & ward_census == "makangila", ward_harm := "makangila"]
spatial_join[mismatch_ward == "yes" & ward_school=="ching'ombe" & ward_census == "chingombe", ward_harm := "chingombe"]
spatial_join[mismatch_ward == "yes" & ward_school=="chinsumbwe" & ward_census == "chinsimbwe", ward_harm := "chinsimbwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="kabulamema" & ward_census == "kabulamena", ward_harm := "kabulamena"]
spatial_join[mismatch_ward == "yes" & ward_school=="kamakechi" & ward_census == "kamankechi", ward_harm := "kamankechi"]
spatial_join[mismatch_ward == "yes" & ward_school=="mukunashi" & ward_census == "mukunanshi", ward_harm := "mukunanshi"]
spatial_join[mismatch_ward == "yes" & ward_school=="kamampanda" & ward_census == "kamapanda", ward_harm := "kamapanda"]
spatial_join[mismatch_ward == "yes" & ward_school=="shikombwe" & ward_census == "shinkombwe", ward_harm := "shinkombwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="lyamakumba" & ward_census == "lyamakumbi", ward_harm := "lyamakumbi"]
spatial_join[mismatch_ward == "yes" & ward_school=="kalyanyembe" & ward_census == "kalwanyembe", ward_harm := "kalwanyembe"]
spatial_join[mismatch_ward == "yes" & ward_school=="lukusanshi" & ward_census == "lukunsanshi", ward_harm := "lukunsanshi"]
spatial_join[mismatch_ward == "yes" & ward_school=="kanakatapa" & ward_census == "kanakantapa", ward_harm := "kanakantapa"]
spatial_join[mismatch_ward == "yes" & ward_school=="sinandambwe" & ward_census == "sinadambwe", ward_harm := "sinadambwe"]
spatial_join[mismatch_ward == "yes" & ward_school=="sansamwenje" & ward_census == "sasamwenje", ward_harm := "sasamwenje"]
spatial_join[mismatch_ward == "yes" & ward_school=="chulung'oma" & ward_census == "chulungoma", ward_harm := "chulungoma"]
spatial_join[mismatch_ward == "yes" & ward_school=="nthitimila" & ward_census == "nthintimila", ward_harm := "nthintimila"]
spatial_join[mismatch_ward == "yes" & ward_school=="kikonkomene" & ward_census == "kikonkomeme", ward_harm := "kikonkomeme"]
spatial_join[mismatch_ward == "yes" & ward_school=="tuvwananai" & ward_census == "tuvwanganai", ward_harm := "tuvwanganai"]
spatial_join[mismatch_ward == "yes" & ward_school=="mwanambunyu" & ward_census == "mwanambuyu", ward_harm := "mwanambuyu"]
spatial_join[mismatch_ward == "yes" & ward_school=="kalungwishi" & ward_census == "kulungwishi", ward_harm := "kulungwishi"]
spatial_join[mismatch_ward == "yes" & ward_school=="chikonkomene" & ward_census == "chikokomene", ward_harm := "chikokomene"]
spatial_join[mismatch_ward == "yes" & ward_school=="choogo east" & ward_census == "choongo east", ward_harm := "choongo east"]
spatial_join[mismatch_ward == "yes" & ward_school=="mphalansenga" & ward_census == "mphalausenga", ward_harm := "mphalausenga"]
spatial_join[mismatch_ward == "yes" & ward_school=="sandang'ombe" & ward_census == "sandangombe", ward_harm := "sandangombe"]
spatial_join[mismatch_ward == "yes" & ward_school=="dr. mubitana" & ward_census == "dr.mubitana", ward_harm := "dr.mubitana"]
spatial_join[mismatch_ward == "yes" & ward_school=="ntumbachushi" & ward_census == "nthumbachushi", ward_harm := "nthumbachushi"]
spatial_join[mismatch_ward == "yes" & ward_school=="chisha-mwamba" & ward_census == "chisha mwamba", ward_harm := "chisha mwamba"]
spatial_join[mismatch_ward == "yes" & ward_school=="mpidi-kakonga" & ward_census == "mpidi kakonga", ward_harm := "mpidi kakonga"]
spatial_join[mismatch_ward == "yes" & ward_school=="yotamu muleya" & ward_census == "yotam muleya", ward_harm := "yotam muleya"]
spatial_join[mismatch_ward == "yes" & ward_school=="mwange-nyawanda" & ward_census == "mwange nyawanda", ward_harm := "mwange nyawanda"]
spatial_join[mismatch_ward == "yes" & ward_school=="john kampengele" & ward_census == "john kapengele", ward_harm := "john kapengele"]
spatial_join[mismatch_ward == "yes" & ward_school=="mapachi-chinyingi" & ward_census == "mapachi chinyingi", ward_harm := "mapachi chinyingi"]
spatial_join[mismatch_ward == "yes" & ward_school=="kalombo kamusamba" & ward_census == "kalombo kamisamba", ward_harm := "kalombo kamisamba"]
spatial_join[mismatch_ward == "yes" & ward_school=="kambuya mukelangombe" & ward_census == "kambuwa mukelangombe", ward_harm := "kambuwa mukelangombe"]
spatial_join[mismatch_ward == "yes" & ward_school=="nyatanda-nyambingila" & ward_census == "nyatanda nyambingila", ward_harm := "nyatanda nyambingila"]

#Where similarity score is low but edits are  needed
spatial_join[mismatch_ward == "yes" & ward_school=="remmy chisupa" & ward_census == "chisupa", ward_harm := "chisupa"]
spatial_join[mismatch_ward == "yes" & ward_school=="mwalala (mwale)" & ward_census == "mwalala", ward_harm := "mwalala"]
spatial_join[mismatch_ward == "yes" & ward_school=="jumbo/kkoma" & ward_census == "jumbo", ward_harm := "jumbo"]
spatial_join[mismatch_ward == "yes" & ward_school=="mazabuka" & ward_census == "mazabuka central", ward_harm := "mazabuka central"]
spatial_join[mismatch_ward == "yes" & ward_school=="kaluweza/ngabo" & ward_census == "ngabo", ward_harm := "ngabo"]
spatial_join[mismatch_ward == "yes" & ward_school=="chambi-mandalo" & ward_census == "chambi", ward_harm := "chambi"]
spatial_join[mismatch_ward == "yes" & ward_school=="mateyo" & ward_census == "mateyo mzeka", ward_harm := "mateyo mzeka"]



#correct for OBservations with ward_school changing over time
#--> revealed after doing: check <- spatial_join[districts_similar_harm== 1 & wards_similar_harm !=1 & ward_harm != "NA"]
spatial_join[school_num==777, ward_harm := "kapumba"]
spatial_join[school_num==802, ward_harm := "kapumba"]
spatial_join[school_num==807, ward_harm := "kapumba"]
spatial_join[school_num==991, ward_harm := "mwembeshi"]
spatial_join[school_num==1468, ward_harm := "keemba"]
spatial_join[school_num==1719, ward_harm := "mulundu"]
spatial_join[school_num==1860, ward_harm := "nalumpembe"]
spatial_join[school_num==2542, ward_harm := "chisha mwamba"]
spatial_join[school_num==4203, ward_harm := "chin'onwe"]
spatial_join[school_num==4300, ward_harm := "sikabenga"]
spatial_join[school_num==9946, ward_harm := "chikola"]
spatial_join[school_num==3020052, ward_harm := "chilongolo"]


spatial_join[, mismatch_ward := NULL]


# ----> RE-TEST
# Assign score based on ward_harm
spatial_join[, wards_string := paste (ward_harm,ward_census, sep=" ; ")] 
spatial_join[, wards_similar_harm := levenshteinSim(strsplit(wards_string, " ; ")[[1]][1],strsplit(wards_string, " ; ")[[1]][2]), by =school_num]
spatial_join[, wards_string := NULL]
spatial_join <- spatial_join %>% relocate(wards_similar_harm, .after=wards_similar)


spatial_join[districts_similar_harm== 1 & wards_similar_harm== 1, .N]
# [initial]    Number of obs with same district & wards names: 35,097 (out of 70267 with same harmonized districts)
# [harmonized] number of obs with same district & wards names: 41,982 (out of 70267 with same harmonized districts)




#********************* CASE 3: same district, different wards

# ----> TEST
spatial_join[districts_similar_harm== 1 & wards_similar_harm !=1, .N]
# [harmonized] number of obs with same district names & different wards names: 28,730 (out of 70,712 with same harmonized districts)

spatial_join[districts_similar_harm== 1 & ward_harm == "NA", .N]
# Number of obs with ward names as "NA": 28,730





# ----> ADJUST

#-> Create table with mismatches
mismatches <- spatial_join[districts_similar_harm== 1 & ward_harm == "NA"]

#-> Reduce to single year
mismatches[, latest := max(year), by= school_num]
mismatches <- mismatches[year==latest]
 
# --> 1. COMPUTATIONAL SOLUTION - Part 1:
#     By default we harmonize everything to reflect the information entered by the school master,
#     unless the school is more that 15km away from the indicated ward. i


#-> Create 15 km buffer around schools
mismatches <- st_as_sf(mismatches, crs = 4326, agr = "constant")
mismatches_buffered = st_buffer(mismatches, dist= 0.15)
rm(mismatches)

#-> Create a simpler version of zambia_wards.sf with just a handful of variables for the purpose of our analysis
wards.sf <- geojsonsf::geojson_sf("Zambia_Wards-2010-Census/Fixed_names_and_geometries_Zambia_Wards_2014t.prj_fixedgeom.geojson") # Load geojson to sf
wards.sf = st_transform(wards.sf, 4326)  # Otherwise it does not overlap

wards.dt <- setDT(wards.sf)
wards.dt[,c("OBJECTID","PROV_CODE","pop_densit","PROVINCENA","DISTRICT_C","Shape_Area","mismatch","DISTRICTNA","ID","CONST_CODE","Area_SQKm","WARD_CODE","Pop2010","perimeter","Shape_Leng","CONST_NAME") := .(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)]
wards.dt[,WARD_NAME := tolower(WARD_NAME)]
wards.dt[,district_harm := tolower(district_harm)]
wards.dt[,int.WARD_NAME := WARD_NAME][,WARD_NAME := NULL]
wards.dt[,int.district_harm := district_harm][,district_harm := NULL]
wards.sf <- st_as_sf(wards.dt, crs = 4326, agr = "constant")    
rm(wards.dt)

#-> By using st_intersect, tie to each school to wards that are within 15km distance 
within15km <- st_intersection(mismatches_buffered, wards.sf)
within15km <- setDT(within15km)
setkey(within15km,school_num)
rm(mismatches_buffered)

#-> Compute the similarity score between the schools' names and the names of each ward within that 15km distance
within15km[, districts_string := paste (ward_school,int.WARD_NAME, sep=" ; ")] 
within15km[, same_name_15km_check := levenshteinSim(strsplit(districts_string, " ; ")[[1]][1],strsplit(districts_string, " ; ")[[1]][2]), by =.(school_num,int.WARD_NAME)]


#-> For each school, create a variable that indicates highest name similarity within 15km
within15km[, highest_similarity := max(same_name_15km_check), by= school_num]

within15km <- within15km[district_harm == int.district_harm & highest_similarity == same_name_15km_check,, by= .(school_num,school_name)]
within15km <- within15km[between(highest_similarity, 0.7, 1)]


#* we've got 1807 (out of 2744) observations for which the ward "indicated by the schoolmaster", 
#* although not the same than the one within which they fall (as per the spatial join) is within
#* 15km of the provided GPS information, and, very important, within the same district.



#-> Retrieve school numbers of schools with a successful ward match within 15km 
similar_within15km <- list() 
for (i in 1:nrow(within15km)) {
  similar_within15km <- append (similar_within15km, within15km[i,school_num[[1]]])
}

#-> Retrieve corresponding districts from the wards map
names_similar_within15km <- list() 
for (i in 1:nrow(within15km)) {
  names_similar_within15km <- append (names_similar_within15km, within15km[i,int.WARD_NAME[[1]]])
}

#-> Correct for those in the SPATIAL JOIN LIST
for (i in 1:length(similar_within15km)) {
  spatial_join[school_num == similar_within15km[[i]], ward_harm := names_similar_within15km[[i]]]
}
rm(names_similar_within15km,similar_within15km)


# ----> RE-TEST

# Re-Assign score based on ward_harm
spatial_join[, wards_string := paste (ward_harm,ward_census, sep=" ; ")] 
spatial_join[, wards_similar_harm := levenshteinSim(strsplit(wards_string, " ; ")[[1]][1],strsplit(wards_string, " ; ")[[1]][2]), by =school_num]
spatial_join[, wards_string := NULL]
spatial_join <- spatial_join %>% relocate(wards_similar_harm, .after=wards_similar)


# Checking how many "NA" ward_harm values have been figured out using the 15km range
spatial_join[districts_similar_harm== 1 & ward_harm == "NA", .N]
# [initial] Number of obs with ward names as "NA": 28,730
# [after adjustment] Number of obs with ward names as "NA": 8,988

#
spatial_join[districts_similar_harm== 1 & wards_similar_harm !=1, .N]
# [initial] number of obs with same district names & different wards names: 28,730 (out of 70267 with same harmonized districts)
# [after adjustment] number of obs with same district names & different wards names: 28,352  (out of 70267 with same harmonized districts)


# ---->  2. COMPUTATIONAL SOLUTION - Part 2:

#---> REMAINING "NA" OBSERVATIONS
#* it's worth noting that we were using the latest year recorded for each school observation in part 1.
#*  So ->
#* Try to find those schools that had a change in the ward name they reported over time, 
#* and if yes use the other ward name to repeat the 15km exercise. If they never changed 
#* (or the old name is not within 15km), check if that ward name exists anywhere. If not, 
#* just take the gps ward


#-> Create table with mismatches
mismatches <- spatial_join[districts_similar_harm== 1 & ward_harm == "NA"]

#-> Changing ward names 
mismatches <- mismatches[unique_ward == FALSE]

#-> Reduce to single year
mismatches[, earliest := min(year), by= school_num]
mismatches <- mismatches[year==earliest]

#-> Create 15 km buffer around schools
mismatches <- st_as_sf(mismatches, crs = 4326, agr = "constant")
mismatches_buffered = st_buffer(mismatches, dist= 0.15)
rm(mismatches)

#-> By using st_intersect, tie to each school to wards that are within 15km distance 
within15km <- st_intersection(mismatches_buffered, wards.sf)
within15km <- setDT(within15km)
setkey(within15km,school_num)
rm(mismatches_buffered)

#-> Compute the similarity score between the schools' names and the names of each ward within that 15km distance
within15km[, districts_string := paste (ward_school,int.WARD_NAME, sep=" ; ")] 
within15km[, same_name_15km_check := levenshteinSim(strsplit(districts_string, " ; ")[[1]][1],strsplit(districts_string, " ; ")[[1]][2]), by =.(school_num,int.WARD_NAME)]

#-> For each school, create a variable that indicates highest name similarity within 15km
within15km[, highest_similarity := max(same_name_15km_check), by= school_num]
within15km <- within15km[district_harm == int.district_harm & highest_similarity == same_name_15km_check,, by= .(school_num,school_name)]
within15km <- within15km[between(highest_similarity, 0.7, 1)]


#* just a quick update: 113 from the remaining 943 observations had changing ward values (over time),
#* and from the 113, we indeed have about 48 schools which where successfully matched with a ward 
#* following the 15km exercice, using their earlier ward name.

#-> Retrieve school numbers of schools with a successful ward match within 15km 
similar_within15km <- list() 
for (i in 1:nrow(within15km)) {
  similar_within15km <- append (similar_within15km, within15km[i,school_num[[1]]])
}

#-> Retrieve corresponding districts from the wards map
names_similar_within15km <- list() 
for (i in 1:nrow(within15km)) {
  names_similar_within15km <- append (names_similar_within15km, within15km[i,int.WARD_NAME[[1]]])
}

#-> Correct for those in the SPATIAL JOIN LIST
for (i in 1:length(similar_within15km)) {
  spatial_join[school_num == similar_within15km[[i]], ward_harm := names_similar_within15km[[i]]]
}
rm(names_similar_within15km,similar_within15km,within15km,i)


# ----> RE-TEST


# Checking how many "NA" ward_harm values have been figured out using the 15km range
spatial_join[districts_similar_harm== 1 & ward_harm == "NA", .N]
# [initial] Number of obs with ward names as "NA": 9,504
# [after 2nd adjustment] Number of obs with ward names as "NA": 8,988









# ---->  3. COMPUTATIONAL SOLUTION - Part 3:  LAST TIER OF "NA" OBSERVATIONS 

#* If schools never changed (or the old name is not within 15km), check if that ward name exists anywhere. 
#* If not, just take the gps ward



# 3.1: Check which of the (mismatched) wards are not on the list of 1421 total wards ************************************************************88**

#->a. Reduce to single year
mismatches <- spatial_join[districts_similar_harm== 1 & ward_harm == "NA"]
mismatches[, latest := max(year), by= school_num]
mismatches <- mismatches[year==latest]


#->b. Get a list of all 1421 wards in the table

wards.sf <- geojsonsf::geojson_sf("Zambia_Wards-2010-Census/Fixed_names_and_geometries_Zambia_Wards_2014t.prj_fixedgeom.geojson") # Load geojson to sf
wards.sf = st_transform(wards.sf, 4326)  # Otherwise it does not overlap
wards.dt <- setDT(wards.sf)
wards.dt[,WARD_NAME := tolower(WARD_NAME)]
wards.dt[,district_harm := tolower(district_harm)]
wards.sf <- st_as_sf(wards.dt, crs = 4326, agr = "constant")    

ward_names <- list() 
for (i in 1:nrow(wards.dt)) {
  ward_names <- append (ward_names, wards.dt[i,WARD_NAME[[1]]])
}
rm(i,wards.dt)

#->c. Assess each row of mismatch for if the ward_school indicated is in the list of 1421 total wards
mismatches[,isinwardslist :=0]

for (i in 1:length(ward_names)) {
  mismatches[ward_school == ward_names[[i]], isinwardslist := 1]
}
rm(i,ward_names)

#->c. Check which of the (mismatched) wards are not on the list of 1421 total wards
check <- mismatches[isinwardslist == 0]
rm(check)


# 3.2: just take the GPS WARD for all *********************************************************************************************************************


#-> Retrieve school numbers of schools in this last Tier of the mismatches
schoolnumbers <- list() 
for (i in 1:nrow(mismatches)) {
  schoolnumbers <- append (schoolnumbers, mismatches[i,school_num[[1]]])
}


#-> Correct for those in the SPATIAL JOIN LIST by assigning the GPS WARD as ward_harm
for (i in 1:length(schoolnumbers)) {
  spatial_join[school_num == schoolnumbers[[i]], ward_harm := ward_census]
}
rm(schoolnumbers,i)


# ----> RE-TEST

# Checking how many "NA" ward_harm values have been figured out using the 15km range
spatial_join[districts_similar_harm== 1 & ward_harm == "NA", .N]
# [after 2nd adjustment] Number of obs with ward names as "NA": 8,988
# [after 3rd adjustment] Number of obs with ward names as "NA": 0




#********************* CASE  4: different district, similar ward

# TEST
spatial_join[districts_similar_harm== 1, .N]
# Number of obs with same district names: 70,712
spatial_join[districts_similar_harm!= 1, .N]
# Number of obs with different district names: 6,935

mismatches <- spatial_join[districts_similar_harm!= 1]

mismatches[wards_similar_harm== 1, .N]
# 1,035
mismatches[between(wards_similar, 0.7, .99), .N]
# 156
check <- mismatches[between(wards_similar, 0.7, .99)]
check[wards_similar_harm != 1, .N]
# 156 
mismatches[between(wards_similar, 0, .69), .N]
# 5,756


# ----> ADJUST

#correct for those observations
spatial_join[school_num==2703, ward_harm := "mukulika"]
spatial_join[school_num==3535, ward_harm := "mwininyilamba"]
spatial_join[school_num==3538, ward_harm := "mwininyilamba"]
spatial_join[school_num==3547, ward_harm := "kanongesha"]
spatial_join[school_num==3550, ward_harm := "kanongesha"]
spatial_join[school_num==3568, ward_harm := "kanongesha"]
spatial_join[school_num==3574, ward_harm := "kanongesha"]
spatial_join[school_num==3577, ward_harm := "kanongesha"]
spatial_join[school_num==3580, ward_harm := "mwininyilamba"]
spatial_join[school_num==3585, ward_harm := "kanongesha"]
spatial_join[school_num==5192, ward_harm := "kanongesha"]
spatial_join[school_num==7400, ward_harm := "kasengo"]


# ----> RE-TEST
# Assign score based on ward_harm
spatial_join[, wards_string := paste (ward_harm,ward_census, sep=" ; ")] 
spatial_join[, wards_similar_harm := levenshteinSim(strsplit(wards_string, " ; ")[[1]][1],strsplit(wards_string, " ; ")[[1]][2]), by =school_num]
spatial_join[, wards_string := NULL]
spatial_join <- spatial_join %>% relocate(wards_similar_harm, .after=wards_similar)

# Re-extract tables 
mismatches <- spatial_join[districts_similar_harm!= 1]

mismatches[wards_similar_harm== 1, .N]
# 1,035 --> 1,179

mismatches[between(wards_similar, 0.7, .99), .N]
# 156

check <- mismatches[between(wards_similar, 0.7, .99)]
check[wards_similar_harm != 1, .N]
# 156 --> 0

mismatches[between(wards_similar, 0, .69), .N]
# 5,756


#********************* CASE  5: different district, same ward 

# TEST
spatial_join[districts_similar_harm== 1, .N]
# Number of obs with same district names: 70,712
spatial_join[districts_similar_harm!= 1, .N]
# Number of obs with different district names: 6,935

mismatches <- spatial_join[districts_similar_harm!= 1]

# Number of obs with Same harmonized Ward names but with different district names: 
mismatches[wards_similar_harm== 1, .N]
## [1] 1179

# Number of obs with Same harmonized Ward names  and different but ACCEPTED harmonized district names: 
mismatches[wards_similar_harm == 1 & districts_similar_harm == 1.1 , .N]
## [1] 0


# ----> ADJUST

# Case 6: please check if the same ward name exists in the district name that the headmaster reports. If not, take the GPS district
# if the same ward name exists in the district the headmaster mentioned, I would disregard the GPS. But failing that, it seems a if
# GPS and headmaster ward match, that can be trusted.



#* CORRECTING 1: for Ikelenge observations
#* seems that part of the mwinilunga became ikelenge 
#* And Despite the fact that there isn't a perfect match between district_harm & district_school (unlike the other ~70,000 successful matches),
#* I will still consider it as a successful match (one that is not to be discarded)


spatial_join[school_num ==3534 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3535 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3536 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3537 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3538 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3541 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3544 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3547 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3548 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3550 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3552 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3558 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3561 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3567 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3568 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3572 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3574 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3577 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3578 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3580 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3585 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3586 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3589 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3590 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==3591 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==4494 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==5189 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==5190 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==5192 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==5193 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==80310 & district_harm == "ikelenge", districts_similar_harm := 1.1]
spatial_join[school_num ==800128 & district_harm == "ikelenge", districts_similar_harm := 1.1]


#* CORRECTING 2: for the rest (only 820 obsservations); They would be treated the same ( district_harm will remain as such & districts_similar_harm will be changed to 1.1 )

#a.Make a list of the harmonized names

mismatches <- spatial_join[districts_similar_harm!= 1]
check <- mismatches[wards_similar_harm== 1]
remaining_unmatched <- check[districts_similar_harm != 1.1]

# Reduce to single year observations
remaining_unmatched[, latest := max(year), by= school_num]
remaining_unmatched <- remaining_unmatched[year==latest]

# Make list of schools in that table
schoolnums <- list() 
for (i in 1:nrow(remaining_unmatched)) {
  schoolnums <- append(schoolnums, remaining_unmatched[i, school_num[[1]]]) 
}

#b.Edit the group of schools in spatial_join
for (i in 1:length(schoolnums)) {
  spatial_join[school_num == schoolnums[[i]] , districts_similar_harm := 1.1]
}

rm(remaining_unmatched,schoolnums,i)


# ----> RE-TEST


mismatches <- spatial_join[districts_similar_harm!= 1]
check <- mismatches[wards_similar_harm== 1]
# Subset to the group mentioned right above

mismatches[wards_similar_harm== 1, .N]
# From list of obs with district mismatch, the number of obs with perfect ward match is: 1,179

# Number of obs with Same harmonized Ward names but with different district names: 
mismatches[wards_similar_harm== 1, .N]
## [1] 1179

# Number of obs with Same harmonized Ward names and different but ACCEPTED harmonized district names: 
mismatches[wards_similar_harm == 1 & districts_similar_harm == 1.1 , .N]
## [1] 1179

check[districts_similar_harm != 1, .N]
# Re-check how many of the above sub-group have a district mismatch: 1,179 (all)

check[districts_similar_harm != 1.1, .N]
# 0 
mismatches[districts_similar_harm== 1.1, .N]
# 1,179

rm(check)


#********************* CASE  6: different district, different ward ---> DELETE

mismatches <- spatial_join[districts_similar_harm < 1]
#spatial_join <- spatial_join[districts_similar_harm >=1]

fwrite(spatial_join, "zambia_schools_matched.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)



# TESTS

# Total Number of observations
spatial_join[, .N]
## [1] 77647

# Total Number of observations harmonized after solving cases 1 to 6 
spatial_join[districts_similar_harm == 1 | districts_similar_harm == 1.1  , .N]
## [1] 71891

# Total Number of observations NOT harmonized after solving cases 1 to 6 
spatial_join[districts_similar_harm != 1 & districts_similar_harm != 1.1  , .N]
## [1] 5756



#PLOT REMAINING MISMATCHES (THAT WILL BE DISCARDED)

library("ggplot2")
library("ggspatial")
library("RColorBrewer") # display.brewer.all
library("colorRamps") #install.packages("colorRamps")
mismatches <- st_as_sf(mismatches, crs = 4326, agr = "constant")


ggplot(data = zambia_wards.sf) + # Map to be stored in popinfo2020plot
  # a. Colorfill
  geom_sf(color = 'gray58', aes(fill = district_harm), size = .2) +
  scale_fill_manual(values = colorRampPalette(brewer.pal(12, "Paired"))(146)) +
  #scale_fill_brewer(palette = "Paired") +
  theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), panel.background = element_rect(fill = "aliceblue"))  +
  
  # wards.sf
  geom_sf(data = wards.sf, color = "black", fill = "papayawhip", size = .2) +
  
  # MISMATCHES
  #geom_sf(data = mismatches_buffered, fill = alpha("goldenrod",0.5), size = .2) +
  geom_sf(data = mismatches, fill = "black", size = .2) +
  
  # e.Arrow & Scale & Legend
  annotation_scale(location = "br", width_hint = 0.25) +
  annotation_north_arrow(location = "br", which_north = "true", pad_x = unit(0.75, "in"), pad_y = unit(0.5, "in"), style = north_arrow_fancy_orienteering) +
  theme(legend.position = c(0.05, 0.05), legend.justification = c(0, 0)) +   # Use legend.position to manually position legend
  theme(legend.position = "none") #-> Remove legend















# 4. CREATING A BRIDGE   *****************************************************************************************************************************************

#*********  0.Clean Workspace and set directory & Load Packages

# Clear console with control + L
rm(list=ls())
setwd("/Users/hassanemeite/Documents/To Phd:Masters/Zambia - Rural Electrification Collaborative Research project")

# 1.0
require(data.table)



#*********  1. LOAD RELEVANT FILES 

# a. Succesful matchs  ************************************************
schools<- fread("zambia_schools_matched.csv")
setkey(schools,ward_harm)

# a. No GPS files  ************************************************
schools_nocoord<- fread("zambia_schools_adjusted.csv")
schools_nocoord <- schools_nocoord[ !is.na(lat)==FALSE] 
schools_nocoord[,district := district_emis][, district_emis := NULL]
schools_nocoord[,ward_school := ward][, ward := NULL]
schools_nocoord[,ward_school := tolower(ward_school)][,district := tolower(district)]





#*********  2. CREATE BRIDGE
schools[, harmonized_to := paste (ward_school,ward_harm, sep=" -> ")] 
schools[, count := 1]
bridge <- schools[, (count = sum(count)), by= .(ward_school,harmonized_to,ward_harm)]
bridge[, count := V1][, V1 := NULL]
bridge <- bridge[ward_school !=""] # remove wards with empty names

# Find the more recurrent harmonization value by ward
bridge <- bridge[, max_count := max(count), by= .(ward_school)]
bridge <- bridge[max_count == count][,max_count := NULL]
setkey(bridge, ward_school)

#fwrite(bridge, "harmonization_bridge.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)


#*********  3. MERGE No GPS files with BRIDGE 

#-> Create list of wards from the bridge
ward_school_list <- list() 
for (i in 1:nrow(bridge)) {
  ward_school_list <- append (ward_school_list, bridge[i,ward_school[[1]]])
}

#-> Create corresponding list of wards_harmonized from the bridge
ward_harm_list <- list() 
for (i in 1:nrow(bridge)) {
  ward_harm_list <- append (ward_harm_list, bridge[i,ward_harm[[1]]])
}


#-> Matching
schools_nocoord[, ward_harm := "NA"]

for (i in 1:length(ward_school_list)) {
  schools_nocoord[ward_school == ward_school_list[[i]], ward_harm := ward_harm_list[[i]]]
}
rm(ward_school_list,ward_harm_list)


#-> Create match_status variable determining which of the obs have perfect match or not 
schools_nocoord[, match_status := "no_match"]
schools_nocoord[ward_harm != "NA" , match_status := "match"]
schools_nocoord[,table(match_status)] # out of the 52,095 observations, 44,565 (85.5%) are successfully matched.

#-> SAVE
fwrite(schools_nocoord, "harmonized_noGPS.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)


#-> Check the remaining unmatched observations
remaining_noGPS <- schools_nocoord[ match_status == "no_match"]
remaining_noGPS[ ward_school == "", .N]
remaining_noGPS <- remaining_noGPS[ ward_school != ""]

remaining_noGPS[, latest := max(year), by= school_num]
remaining_noGPS <- remaining_noGPS[year==latest]
#fwrite(remaining_noGPS, "remaining_noGPS.csv", sep=",", na="", row.names=FALSE, col.names=TRUE)





# 5. RESULTS SUMMARY AS WATERFALL CHARTS   *****************************************************************************************************************************************

rm(list=ls())
require(data.table)
library("ggplot2")

#-> 5.1 Creating table
cascade_table<- data.table(id=numeric(), desc=character(), Type=character(), start=numeric(), end=numeric(), amount = numeric(), cond = character())

#-> 5.2 Adding catergories
cascade_table <- rbind(cascade_table, data.table(id=1, desc="a.Total_GPS", Type="Total", start=77647, end=0, amount=77647, cond = "total"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="a.Total_matched", Type="matched", start=77647, end=5756, amount=71891, cond = "no"))
cascade_table <- rbind(cascade_table, data.table(id=3, desc="Case 1", Type="matched", start=77647, end=42550, amount = 35097, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=4, desc="Case 2", Type="matched", start=42550, end=35665, amount = 6885, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=5, desc="Case 3", Type="matched", start=35665, end=6935, amount= 28730, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=6, desc="Case 4", Type="matched", start=6935, end=6935, amount=0, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=7, desc="Case 5", Type="matched", start=6935, end=5756, amount=1179, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=8, desc="Case 6", Type="discarded", start=5756, end=0, amount=5756, cond = "no"))
cascade_table <- rbind(cascade_table, data.table(id=9, desc="Total_noGPS", Type="Total", start=52095, end=0, amount=52095, cond = "total"))
cascade_table <- rbind(cascade_table, data.table(id=10, desc="z.Bridged", Type="matched", start=52095, end=8339, amount=43756, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=11, desc="z.Discarded", Type="discarded", start=8339, end=0, amount=8339, cond = "no"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="Case 1", Type="matched", start=77647, end=42550, amount = 35097, cond = "yes"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="Case 2", Type="matched", start=42550, end=35665, amount = 6885, cond = "yes"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="Case 3", Type="matched", start=35665, end=6935, amount= 28730, cond = "yes"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="Case 4", Type="matched", start=6935, end=6935, amount=0, cond = "yes"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="Case 5", Type="matched", start=6935, end=5756, amount=1179, cond = "yes"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="Case 6", Type="discarded", start=5756, end=0, amount=5756, cond = "yes"))

labels = c("Total_GPS","Total_matched","Case 1","Case 2","Case 3","Case 4","Case 5","Case 6","Total_noGPS","Bridged","Discarded")

#-> 5.3 PLOT
ggplot(cascade_table, aes(cascade_table, fill = Type)) + 
  geom_rect(aes(x = desc, xmin = id - 0.45, xmax = id + 0.45, ymin = end, ymax = start)) +
  # 1.Labels
  geom_text(aes(x= id, y= ifelse(desc !="Case 4",rowSums(cbind(start,-amount/2)),rowSums(cbind(start,1500))) ,label = ifelse(cond =="yes"| cond == "yes_bar",desc,"")), color = "black", size=2.5) + # Adding labels in column two
  geom_text(aes(x= id, y = rowSums(cbind(start,-amount/2)) ,label = ifelse(cond =="total",as.character(amount),"")), color = "black", fontface= "bold") + # Adding labels totals
  # 2.segments
  geom_segment(aes(x=ifelse(cond =="bar"| cond == "yes_bar",id - 0.45, 0), xend=ifelse(cond =="bar" | cond == "yes_bar",id + 1.45, 0), y=end, yend=end), colour="black") + # Adding connecting bars between columns
  geom_segment(aes(x=ifelse(cond =="yes",id - 0.45, 0), xend=ifelse(cond =="yes",id + 0.45, 0), y=end, yend=end), colour="black") + # Adding separating bars in column two
  # 3.Axis names 
  ylab(" Number of Observations ") + # Change y axis Name
  scale_x_discrete('cascade_table', labels = labels) + # Manual set up for labels
  # 4.aesthethics
  theme_minimal()


#->******************************************************* 5.4 Table Variant  1
cascade_table<- data.table(id=numeric(), desc=character(), Type=character(), start=numeric(), end=numeric(), amount = numeric(), cond = character())
cascade_table <- rbind(cascade_table, data.table(id=1, desc="a.Total_GPS", Type="Total", start=77647, end=0, amount=77647, cond = "total"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="Case 1", Type="Matched", start=77647, end=42550, amount = 35097, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=3, desc="Case 2", Type="Matched", start=42550, end=35665, amount = 6885, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=4, desc="Case 3", Type="Matched", start=35665, end=6935, amount= 28730, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=5, desc="Case 4", Type="Matched", start=6935, end=6935, amount=0, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=6, desc="Case 5", Type="Matched", start=6935, end=5756, amount=1179, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=7, desc="Case 6", Type="Discarded", start=5756, end=0, amount=5756, cond = "no"))
cascade_table <- rbind(cascade_table, data.table(id=8, desc="Total_noGPS", Type="Total", start=52095, end=0, amount=52095, cond = "total"))
cascade_table <- rbind(cascade_table, data.table(id=9, desc="z.Bridged", Type="Matched", start=52095, end=8339, amount=43756, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=10, desc="z.Discarded", Type="Discarded", start=8339, end=0, amount=8339, cond = "no"))

labels = c("Total_GPS","Case 1","Case 2","Case 3","Case 4","Case 5","Case 6","Total_noGPS","Bridged","Discarded")

ggplot(cascade_table, aes(cascade_table, fill = Type)) + 
  geom_rect(aes(x = desc, xmin = id - 0.45, xmax = id + 0.45, ymin = end, ymax = start)) +
  # 1.Labels
  # geom_text(aes(x= id, y= ifelse(desc !="Case 4",rowSums(cbind(start,-amount/2)),rowSums(cbind(start,1500))) ,label = ifelse(cond =="yes"| cond == "yes_bar",desc,"")), color = "black", size=2.5) + # Adding labels in column two
  geom_text(aes(x= id, y= ifelse(amount !=0,rowSums(cbind(start,-amount/2)),rowSums(cbind(start,1250))) ,label = as.character(amount)), color = "black", fontface= "bold", size=2.5) + # Adding labels  and moving the label up if equal to 0
  # 2.segments
  geom_segment(aes(x=ifelse(cond =="bar"| cond == "yes_bar",id - 0.45, 0), xend=ifelse(cond =="bar" | cond == "yes_bar",id + 1.45, 0), y=end, yend=end), colour="black") + # Adding connecting bars between columns
  geom_segment(aes(x=ifelse(cond =="yes",id - 0.45, 0), xend=ifelse(cond =="yes",id + 0.45, 0), y=end, yend=end), colour="black") + # Adding separating bars in column two
  # 3.Axis names 
  ylab(" Number of Observations ") + # Change y axis Name
  scale_x_discrete('cascade_table', labels = labels) + # Manual set up for labels
  
  # 4.Title
  ggtitle("Breakdown of Matching Outcomes for School-Year Observations") +
  # 5.aesthethics
  theme_minimal()+
  theme(axis.title.x = element_blank()) # Remove X axis title


#->******************************************************* 5.5 Table Variant 2
cascade_table<- data.table(id=numeric(), desc=character(), Type=character(), start=numeric(), end=numeric(), amount = numeric(), cond = character())
cascade_table <- rbind(cascade_table, data.table(id=1, desc="a.Total_GPS", Type="Total", start=77647, end=0, amount=77647, cond = "total"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="a.Total_matched", Type="matched", start=77647, end=5756, amount=71891, cond = "no"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="Case 1", Type="matched", start=77647, end=42550, amount = 35097, cond = "yes"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="Case 2", Type="matched", start=42550, end=35665, amount = 6885, cond = "yes"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="Case 3", Type="matched", start=35665, end=6935, amount= 28730, cond = "yes"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="Case 4", Type="matched", start=6935, end=6935, amount=0, cond = "yes"))
cascade_table <- rbind(cascade_table, data.table(id=2, desc="Case 5", Type="matched", start=6935, end=5756, amount=1179, cond = "yes_bar"))
cascade_table <- rbind(cascade_table, data.table(id=3, desc="Case 6", Type="discarded", start=5756, end=0, amount=5756, cond = "yes"))
cascade_table <- rbind(cascade_table, data.table(id=4, desc="Total_noGPS", Type="Total", start=52095, end=0, amount=52095, cond = "total"))
cascade_table <- rbind(cascade_table, data.table(id=5, desc="z.Bridged", Type="matched", start=52095, end=8339, amount=43756, cond = "bar"))
cascade_table <- rbind(cascade_table, data.table(id=6, desc="z.Discarded", Type="discarded", start=8339, end=0, amount=8339, cond = "no"))

labels = c("Total_GPS","Total_matched","Case 6","Total_noGPS","Bridged","Discarded","","","","","")

ggplot(cascade_table, aes(cascade_table, fill = Type)) + 
  geom_rect(aes(x = desc, xmin = id - 0.45, xmax = id + 0.45, ymin = end, ymax = start)) +
  # 1.Labels
  geom_text(aes(x= id, y= ifelse(desc !="Case 4",rowSums(cbind(start,-amount/2)),rowSums(cbind(start,1500))) ,label = ifelse(cond =="yes"| cond == "yes_bar",desc,"")), color = "black", size=2.5) + # Adding labels in column two
  geom_text(aes(x= id, y = rowSums(cbind(start,-amount/2)) ,label = ifelse(cond =="total",as.character(amount),"")), color = "black", fontface= "bold") + # Adding labels totals
  # 2.segments
  geom_segment(aes(x=ifelse(cond =="bar"| cond == "yes_bar",id - 0.45, 0), xend=ifelse(cond =="bar" | cond == "yes_bar",id + 1.45, 0), y=end, yend=end), colour="black") + # Adding connecting bars between columns
  geom_segment(aes(x=ifelse(cond =="yes",id - 0.45, 0), xend=ifelse(cond =="yes",id + 0.45, 0), y=end, yend=end), colour="black") + # Adding separating bars in column two
  # 3.Axis names 
  ylab(" Number of Observations ") + # Change y axis Name
  scale_x_discrete('cascade_table', labels = labels) + # Manual set up for labels
  # 4.aesthethics
  theme_minimal()

# ***************************************************************************************************************************************************************



#Ideally you have the code run in such a way that it takes your two (or so) input files, runs everything,
#and outputs two files: a bridge and a finished sample of school-years that have a harmonised ward whenever possible

#Also pls make sure to only load packages you actually end up using, as general good practice
