#**********************************************************************************************#
#********************* SETUP:   Clean workspace & set directory          **********************#
#**********************************************************************************************#

#*********  0. Set working directory
# Clear console with control + L
rm(list=ls())
setwd("/Users/hassanemeite/Dropbox/SoilRoadAfrica")

install.packages("PerformanceAnalytics")

#*********  1. Install & Load Packages
#install.packages("zoo")
#install.packages("haven")
#install.packages("data.table")
#install.packages("RecordLinkage")


# R Markdown
#install.packages("rmarkdown")
#install.packages("knitr")
# install.packages("htmltools")


#********* 1.1 Clear workspace
rm(list=ls())

#********* 1.2 Load Packages
require(data.table)

# We start by loading the basic packages necessary for all maps, i.e. ggplot2 and sf. 
library("sf")
library("sp")
# library("dplyr") # For relocate() feature
library("rgeos") # for Gbuffer


# R wrapper around GDAL/OGR
library(rgdal)

# geojson
library(geojsonsf)
library(jsonlite)

# For comparing words
# require(RecordLinkage)

# For Zonal statistics
library(exactextractr)
library(velox) # Much faster
library(raster)
library("rasterVis") # for levelplot()
# --> Plotting Raster with Levelplot
#library(scales)
#library(grid)
library(viridis)
#library(ggthemes)

# For Plotting purposes
library("ggplot2")
library("ggspatial")
library("RColorBrewer") # display.brewer.all
library("colorRamps") #install.packages("colorRamps")

# Checking time count
library("tictoc")

#********* 1.3 Define root directory
rootpath <- getwd()

#********* 1.4 Define paths
controlspath <- paste0(rootpath,"/data/controls/")
mapspath <- paste0(controlspath,"maps/")










#**********************************************************************************************************#
#*********************          TASK 1: EXTRACT DATA ON CONTROL VARIABLES            **********************#
#**********************************************************************************************************#

# ********  1. Load Base Layer

#-> africa_districts.dt
africa_districts.sf <- readOGR(paste0(rootpath,"/cleaned/"), "gadm2")
africa_districts.sf <- st_as_sf(africa_districts.sf, coords = c("long", "lat"), crs = 4326, agr = "constant") # #--> Next the shapefile has to be converted to a sf for use in ggplot2;  WGS84, which is the CRS code #4326)
africa_districts.dt <- setDT(africa_districts.sf) # Create data.table version for export
africa_districts.dt <- africa_districts.dt[,geometry := NULL] # Drop geometry column
for (i in 1:3729){africa_districts.dt[i, unitNo :=i ]}  # For later matching with information from Velox

#-> africa_districts.sf
africa_districts.sf <- readOGR(paste0(rootpath,"/cleaned/"), "gadm2")
africa_districts.sf <- st_as_sf(africa_districts.sf, coords = c("long", "lat"), crs = 4326, agr = "constant") # #--> Next the shapefile has to be converted to a sf for use in ggplot2;  WGS84, which is the CRS code #4326)
africa_districts.sf = st_transform(africa_districts.sf, 4326)  # Otherwise it does not overlap




# ********  2. Extract Control variables



#***************** a. Controls: Distance to coastline

# 1. Load
africa_coastline.sf <- readOGR(paste0(controlspath,"africa_coastline_vmap0/"), "africa_coastline_vmap0")
africa_coastline.sf <- st_as_sf(africa_coastline.sf, coords = c("long", "lat"), crs = 4326, agr = "constant") # #--> Next the shapefile has to be converted to a sf for use in ggplot2;  WGS84, which is the CRS code #4326)
africa_coastline.sf = st_transform(africa_coastline.sf,4326) # Change to same CRS. Otherwise st_intersection is not possible

# 2. Extract: Distance to closest coastline node
nearest=st_nearest_feature(africa_districts.sf,africa_coastline.sf$geometry) # Find id of nearest river node. 
dist = st_distance(africa_districts.sf, africa_coastline.sf[nearest,], by_element=TRUE) # Compute distance to waterbody (for each geographic unit). Note that st_distance returns the distance between a Point and the closest part of a Polygon's boundary 

#-> Add to new information to africa_districts.dt
africa_districts.dt$tocoast_DIST = dist
africa_districts.dt <- africa_districts.dt[tocoast_DIST==0, coastal:= 1][is.na(coastal), coastal:= 0]
#-> remove intermediary datasets 
rm(africa_coastline.sf, nearest,dist )



#***************** b. Controls: Rivers
# 1. Load
africa_rivers.sf <- readOGR(paste0(controlspath,"africa_rivers_1/"), "africa_rivers_1")
africa_rivers.sf <- st_as_sf(africa_rivers.sf, coords = c("long", "lat"), crs = 4326, agr = "constant") # #--> Next the shapefile has to be converted to a sf for use in ggplot2;  WGS84, which is the CRS code #4326)

# 2. Extract: Distance to closest river for each administrative unit
nearest=st_nearest_feature(africa_districts.sf,africa_rivers.sf$geometry) # Find id of nearest river node
dist = st_distance(africa_districts.sf, africa_rivers.sf[nearest,], by_element=TRUE) # Compute distance to waterbody (for each geographic unit)

#-> Add to new information to africa_districts.dt
africa_districts.dt$river_DIST = dist

#-> remove intermediary datasets 
rm(africa_rivers.sf,nearest,dist)




#***************** c. Controls: Waterbodies: Lakes, Lagoons, Reservoirs
# 1. Load
africa_lakes.sf <- readOGR(paste0(controlspath,"waterbodies(Lakes)_africa/"), "waterbodies_africa")
africa_lakes.sf <- st_as_sf(africa_lakes.sf, coords = c("long", "lat"), crs = 4326, agr = "constant") # #--> Next the shapefile has to be converted to a sf for use in ggplot2;  WGS84, which is the CRS code #4326)

# 2. Extract: Distance to closest waterbody for each administrative unit
nearest=st_nearest_feature(africa_districts.sf,africa_lakes.sf$geometry) # Find id of nearest waterbody
dist = st_distance(africa_districts.sf, africa_lakes.sf[nearest,], by_element=TRUE) # Compute distance to waterbody (for each geographic unit)
#-> Add to new information to africa_districts.dt
africa_districts.dt$waterbody_DIST = dist

# 3. Extract: Area and Type of waterbody per administrative unit
spatial_join <- st_intersection(africa_districts.sf, africa_lakes.sf)

#-> Prepare spatial join for Merge
spatial_join$waterbody_AREA <- st_area(spatial_join) # Compute area and assign to new variable called waterbody_AREA
spatial_join <- setDT(spatial_join) # To data.table
waterbody <- dcast(data = spatial_join, gid ~ paste0("waterbody_", TYPE_OF_WA), length) # Hot encode type of waterbody variable (transform to dummies)
spatial_join <- spatial_join[, sum(waterbody_AREA) , by=c("gid")][,waterbody_AREA := V1][, V1:= NULL] # Sum areas per geographic unit; rename V1 column 

#-> Add to new information to africa_districts.dt
africa_districts.dt <- merge(africa_districts.dt, spatial_join, by = c("gid"), all.x = TRUE) # Merge
africa_districts.dt <- africa_districts.dt[is.na(waterbody_AREA), waterbody_AREA:=0] # Replace by zero where there is no water body in the geographic unit
africa_districts.dt <- merge(africa_districts.dt, waterbody, by = c("gid"), all.x = TRUE) # Merge

#-> remove intermediary datasets 
rm(spatial_join, waterbody, africa_lakes.sf,nearest,dist)
                




#***************** d. Controls: Maritime Ports
# 1. Load
africa_seaports.sf <- readOGR(paste0(controlspath,"maritime_ports/"), "marine ports")
africa_seaports.sf <- st_as_sf(africa_seaports.sf, coords = c("long", "lat"), crs = 4326, agr = "constant") # #--> Next the shapefile has to be converted to a sf for use in ggplot2;  WGS84, which is the CRS code #4326)
africa_seaports.sf = st_set_crs(africa_seaports.sf,4326) # Change to same CRS. Otherwise st_intersection is not possible

# 2. Extract: Presence of Maritime port in administrative unit
spatial_join <- st_intersection(africa_districts.sf, africa_seaports.sf)

#-> Prepare spatial join for Merge
spatial_join <- setDT(spatial_join) # To data.table
spatial_join <- spatial_join[, c("gid")][,seaport:=1]

#-> Add to new information to africa_districts.dt
africa_districts.dt <- merge(africa_districts.dt, spatial_join, by = c("gid"), all.x = TRUE) # Merge

#-> remove intermediary datasets 
rm(africa_seaports.sf, spatial_join)





#***************** e. Controls: Malaria index
#-> 1.Load
malaria_raster <-raster(paste0(controlspath,"malaria_index/incidence_rate_LCI_Global_admin0_2000.tif"))
malaria_raster <- raster::crop(malaria_raster, africa_districts.sf) # Crop to BBox around africa_districts.sf
malaria_raster <- raster::mask(malaria_raster, africa_districts.sf) # Crop to exact extent of africa_districts.sf

#-> 2.Extract: Mean of incidence rate per administrative unit
malaria_velox <- velox(malaria_raster) # 1. create VeloxRaster object from imported raster
malaria_mean <- malaria_velox$extract(africa_districts.sf,fun=mean) # 2. Extract mean per unit
malaria_mean <- setDT(as.data.frame(as.table(malaria_mean))) # 3. convert to data.table

#-> Add to new information to africa_districts.dt
malaria_mean <- malaria_mean[,unitNo := Var1][,malaria_mean := Freq][, c("Var1","Var2","Freq") := .(NULL,NULL,NULL)][, unitNo := as.numeric(unitNo)] # prepare file for merge
africa_districts.dt <- merge(africa_districts.dt, malaria_mean, by = c("unitNo"), all.x = TRUE) # Merge

#-> remove intermediary datasets 
rm(malaria_mean, malaria_raster, malaria_velox) # remove intermediary datasets 






#***************** f. Controls: Elevation
# 1. Load
elevation_raster <-raster(paste0(controlspath,"DEM_geotiff/alwdgg.tif"))
elevation_raster <- raster::crop(elevation_raster, africa_districts.sf) # Crop to BBox around africa_districts.sf
elevation_raster <- raster::mask(elevation_raster, africa_districts.sf) # Crop to exact extent of africa_districts.sf

# 2. Extract: Mean of incidence rate per administrative unit
elevation_velox <- velox(elevation_raster) # 1. create VeloxRaster object from imported raster
elevation_mean <- elevation_velox$extract(africa_districts.sf,fun=mean) # 2. Extract mean per unit
elevation_mean <- setDT(as.data.frame(as.table(elevation_mean))) # 3. convert to data.table

#-> Add to new information to africa_districts.dt
elevation_mean <- elevation_mean[,unitNo := Var1][,elevation_mean := Freq][, c("Var1","Var2","Freq") := .(NULL,NULL,NULL)][, unitNo := as.numeric(unitNo)] # prepare file for merge
africa_districts.dt <- merge(africa_districts.dt, elevation_mean, by = c("unitNo"), all.x = TRUE) # Merge

#-> remove intermediary datasets 
rm(elevation_mean, elevation_raster, elevation_velox) # remove intermediary datasets 







#***************** . Controls: Agro-ecological zoning
# 1. Load
africa_agroecozones.sf <- readOGR(paste0(controlspath,"africa_agroecological_zoning/"), "africa_agroecological_zoning")
africa_agroecozones.sf <- gBuffer(africa_agroecozones.sf, byid=TRUE, width=0) # deal with "bad" polygons (other wise we get multiple errors)
africa_agroecozones.sf <- st_as_sf(africa_agroecozones.sf, coords = c("long", "lat"), crs = 4326, agr = "constant") # #--> Next the shapefile has to be converted to a sf for use in ggplot2;  WGS84, which is the CRS code #4326)

#-> To avoid errors
sf_use_s2(FALSE) # Avoid errors of type Edge x has duplicate vertex with edge y.


# 2. Extract: Types of agroecological zones per administrative unit
spatial_join <- st_intersection(africa_districts.sf, africa_agroecozones.sf)

#-> Prepare spatial join for Merge
spatial_join <- setDT(spatial_join) # To data.table
aezones <- dcast(data = spatial_join, gid ~ paste0("agroeco_", AEZ_NAME), length) # Hot encode type of waterbody variable (transform to dummies)

#-> Add to new information to africa_districts.dt
africa_districts.dt <- merge(africa_districts.dt, aezones, by = c("gid"), all.x = TRUE) # Merge

#-> remove intermediary datasets 
rm(africa_agroecozones.sf,aezones,spatial_join) # remove intermediary datasets






#***************** . Controls: Ecoregions
# 1. Load
africa_ecoregions.sf <- readOGR(paste0(controlspath,"Ecoregions2017/"), "Ecoregions2017")
africa_ecoregions.sf <- gBuffer(africa_ecoregions.sf, byid=TRUE, width=0) # deal with "bad" polygons (other wise we get multiple errors)
africa_ecoregions.sf <- st_as_sf(africa_ecoregions.sf, coords = c("long", "lat"), crs = 4326, agr = "constant") # #--> Next the shapefile has to be converted to a sf for use in ggplot2;  WGS84, which is the CRS code #4326)

# 2. Extract: Types of Biome per administrative unit

#-> To avoid errors
sf_use_s2(FALSE) # Avoid errors of type Edge x has duplicate vertex with edge y.


#-> Saved spatial join because intersection Takes too long
# spatial_join <- st_intersection(africa_districts.sf, africa_ecoregions.sf)
# st_write(spatial_join, paste0(controlspath,"Ecoregions2017/africa_ecoregions.geojson")) 
spatial_join <- geojsonsf::geojson_sf(paste0(controlspath,"Ecoregions2017/africa_ecoregions.geojson")) # Load geojson to sf

#-> Prepare spatial join for Merge
spatial_join <- setDT(spatial_join) # To data.table
biomes <- dcast(data = spatial_join, gid ~ paste0("biome_", BIOME_NAME), length) # Hot encode type of waterbody variable (transform to dummies)

#-> Add to new information to africa_districts.dt
africa_districts.dt <- merge(africa_districts.dt, biomes, by = c("gid"), all.x = TRUE) # Merge

#-> remove intermediary datasets 
rm(africa_ecoregions.sf,biomes,spatial_join) # remove intermediary datasets



#***************** . Controls: Mineral Facilities
# 1. Load
mineral_facilities.sf <- readOGR(paste0(controlspath,"mineral facilities of Africa and the Mideast/"), "minfac")
mineral_facilities.sf <- st_as_sf(mineral_facilities.sf, coords = c("long", "lat"), crs = 4326, agr = "constant") # #--> Next the shapefile has to be converted to a sf for use in ggplot2;  WGS84, which is the CRS code #4326)
mineral_facilities.sf <- st_crop(mineral_facilities.sf, africa_districts.sf) # Reduce to extent of africa_districts.sf 

# 2. Extract: Existence and Type of mineral Facility per administrative unit
spatial_join <- st_intersection(africa_districts.sf, mineral_facilities.sf)
spatial_join <- setDT(spatial_join) # To data.table
spatial_join <- dcast(data = spatial_join, gid ~ paste0("mineral_", commodity), length) # Hot encode commodity variable (transform to dummies)

#-> Add to new information to africa_districts.dt
africa_districts.dt <- merge(africa_districts.dt, spatial_join, by = c("gid"), all.x = TRUE) # Merge

#-> remove intermediary datasets 
rm(mineral_facilities.sf,spatial_join)





#***************** SAVE
fwrite(africa_districts.dt, paste0(controlspath,"controls_cleaned.csv"), sep=",", na="", row.names=FALSE, col.names=TRUE)

controls<- fread(paste0(controlspath,"controls_cleaned.csv"))





#*************************************************************************#
#*********************          PLOTTING            **********************#
#*************************************************************************#

#0.PREPARE MACROS

#Expand palette
nb.cols= 526 # number of values needed
plotwidth = 12
plotheight = 9.61
plotunit = "in"
#Expand palette
mycolors <- colorRampPalette(brewer.pal(12, "Paired"))(nb.cols)
# Names
dist_labels <- cbind(africa_districts.sf, st_coordinates(st_centroid(africa_districts.sf$geometry)))



#1.PLOT AFRICA DISTRICTS
(ggplot(data = africa_districts.sf) + 
  
  # 0. Colorfill
  geom_sf(color = 'black', aes(fill = admin1name), size = .1) +
  scale_fill_manual(values = mycolors) +
  theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), panel.background = element_rect(fill = "aliceblue"))  +
  
  # a. Lakes 
  # geom_sf(data = africa_lakes.sf, color = 'cadetblue1', size = 0.1) +

  # b. Rivers 
  # geom_sf(data = africa_rivers.sf, color = 'blue', size = 0.1) + 

  # d. Ecoregions
  # geom_sf(data = africa_agroecozones.sf, aes(color = AEZ_NAME), size = 0.1) +
    
  # d. Coastline
  geom_sf(data = africa_coastline.sf, color = 'black', size = 0.5) +
  
     
  # d. Ecoregions
  # geom_sf(data = africa_ecoregions.sf, aes(color = BIOME_NUM), size = 0.1) +
    
  # c. mineral 
  # geom_sf(data = mineral_facilities.sf, aes(color = commodity), size = 0.2) + 
  
  # c. Labels
  #geom_text(data= dist_labels,aes(x=X, y=Y, label=admin1name), color = "black", fontface = "italic", size = .5, check_overlap = FALSE) +
  
  # e.Arrow & Scale & Legend
  annotation_scale(location = "br", width_hint = 0.25) +
  annotation_north_arrow(location = "br", which_north = "true", pad_x = unit(0.75, "in"), pad_y = unit(0.5, "in"), style = north_arrow_fancy_orienteering) +
  theme(legend.position = c(0.05, 0.05), legend.justification = c(0, 0)) +   # Use legend.position to manually position legend
  theme(legend.position = "none") #-> Remove legend
)
ggsave(paste0(mapspath,"coastline_africa_districts_map.pdf"), device = "pdf", width = plotwidth, height = plotheight, unit = plotunit)




#2.PLOT RASTERS

# a. Malaria
malaria_incidence_map <- 
  levelplot(malaria_raster,
            margin=FALSE,
            colorkey=list(space='bottom',labels=list(at=2:15, font=4),axis.line=list(col='black')),
            maxpixels = 17e5,
  )

pdf(paste0(mapspath,"malaria_incidence_map.pdf"))
print(malaria_incidence_map)
dev.off()


# e. elevation
elevation_map <- 
  levelplot(elevation_raster,
            margin=FALSE,
            colorkey=list(space='bottom',labels=list(at=2:15, font=4),axis.line=list(col='black')),
            maxpixels = 17e5,
  )

pdf(paste0(mapspath,"_elevation_map.pdf"))
print(elevation_map)
dev.off()





# The following are the same:
# malaria_mean <- malaria_mean[, unitNo := as.numeric(unitNo)]
# malaria_mean <- malaria_mean %>% mutate(unitNo = as.numeric(unitNo))
