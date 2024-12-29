
#**********************************************************************************************************************#
#*************         TASK 3:   SPATIAL JOIN FOR MATCHING PURPOSES            ********************#
#**********************************************************************************************************************#

#*********  0.Clean Workspace and set directory

# Clear console with control + L
rm(list=ls())
setwd("/Users/hassanemeite/Documents/To Phd:Masters/Zambia - Rural Electrification Collaborative Research project")


#*********  1.Load Packages

# 1.0
require(zoo)
require(haven)
require(data.table)

# 1.1 We start by loading the basic packages necessary for all maps, i.e. ggplot2 and sf. 
library("ggplot2")
library("sf")
library("sp")

# 1.2 The package rnaturalearth provides a map of countries of the entire world.
library("rnaturalearth")
library("rnaturalearthdata") # (rnaturalearthhires is necessary for scale = "large"). 
library("rnaturalearthhires")

# 1.3 Correct error: rgeos required for finding out which hole belongs to which exterior ring
library("rgeos")

# 1.4 Several packages are available to create a scale bar on a map. We introduce here the package ggspatial, which provides easy-to-use functions
library("ggspatial")

# 1.5  The package maps provides maps of the USA, with state and county borders
library("maps")

# 1.6 To capitalize names
library("tools")

# 1.7 Deal with geomtetries
library("lwgeom")

# 1.8 Label placement: The package ggrepel offers a very flexible approach to deal with label placement, including automated movement of labels in case of overlap. 
library("ggrepel")

# 1.9 Complex layout: Two maps on the same Layout
library("cowplot")

# 2.10 
library(rgdal)     # R wrapper around GDAL/OGR

library(RColorBrewer)  # For R color palette
#display.brewer.all()

# 2.11
library(raster) # import raster

# 1.6 Display OSM tiles
library("rosm")

# 1.7 geojson
library(geojsonsf)
library(jsonlite)



#*********  2. PREPARE LAYOUT


# a. schools
schools<- fread("zambia_schools_adjusted.csv")
# Reduce to single year observations
schools[, latest := max(year), by= school_num]
schools <- schools[year==latest]

# Add binary distinction for map
schools[, powersourcelegend :="no grid (EMIS School Electricity Status)"][powersource=="grid",powersourcelegend :="grid (EMIS School Electricity Status)"]

# Transform to simple feature
schools <- schools[ is.na(lat)==FALSE]
schools.sf <- st_as_sf(schools, coords = c("lon", "lat"), crs = 4326, agr = "constant") #  WGS84, which is the CRS code #4326)


# b. Zambia Map
zambia_wards.sf <- readOGR("QGIS files/UNDRR-Wards-2020/", "UNDRR-wards2017_population2010_join")
zambia_wards.sf <- st_as_sf(zambia_wards.sf, coords = c("long", "lat"), crs = 4326, agr = "constant") # #--> Next the shapefile has to be converted to a sf for use in ggplot2;  WGS84, which is the CRS code #4326)

#convert, add namelegend, reconvert
zambia_wards.dt <- setDT(zambia_wards.sf)
zambia_wards.dt <- zambia_wards.dt[, namelegend :="Zambia Wards 2017"]
zambia_wards.sf <- st_as_sf(zambia_wards.dt, crs = 4326, agr = "constant") #  WGS84, which is the CRS code #4326)

zambia_districts <- readOGR("Matching districts/population_census_2010/", "geo2_zm2010")
zambia_districts <- st_as_sf(zambia_districts, coords = c("long", "lat"), crs = 4326, agr = "constant") # #--> Next the shapefile has to be converted to a sf for use in ggplot2;  WGS84, which is the CRS code #4326)

# c. Zambia Background
world <- ne_countries(scale = "medium", returnclass = "sf") 
zambia <- subset(world, admin == "Zambia")


# c. Power info

# SUBSTATIONS
substations.sf <- geojsonsf::geojson_sf("substation_info/OSM-Overpass-Zambia-power_substation_with_coord-2021.geojson") # Create file from that country's data
# Add column and reconvert
#-> to DT
substations.dt <- setDT(substations.sf)
#-> x,y cords
substations.dt[, xcoord := lapply(substations.dt$geometry, `[[`, 1)]
substations.dt[, ycoord := lapply(substations.dt$geometry, `[[`, 2)]
substations.dt[, geometry := NULL]
#-> Add column
substations.dt <- substations.dt[, namelegend :="OSM Overpass Substations 2021"]
#-> Reconvert
substations.sf <- st_as_sf(substations.dt, coords = c("xcoord", "ycoord"), crs = 4326, agr = "constant") #  WGS84, which is the CRS code #4326)


#TOWERS
towers.sf <- geojsonsf::geojson_sf("substation_info/OSM-Overpass-Zambia-power_towers_with_coord-2021.geojson") # Create file from that country's data
# Limit towers.sf to Zambian territory
towers.sf <- st_intersection(towers.sf, zambia_districts)
# Add column and reconvert

#-> to DT
towers.dt <- setDT(towers.sf)
#-> x,y cords
towers.dt[, xcoord := lapply(towers.dt$geometry, `[[`, 1)]
towers.dt[, ycoord := lapply(towers.dt$geometry, `[[`, 2)]
towers.dt[, geometry := NULL]
#-> Add column
towers.dt <- towers.dt[, namelegend :="OSM Overpass Towers/Poles 2021"]
#-> Reconvert
towers.sf <- st_as_sf(towers.dt, coords = c("xcoord", "ycoord"), crs = 4326, agr = "constant") #  WGS84, which is the CRS code #4326)


#*********  3.  PLOT

ggplot(data = zambia) +
  # a. Background
  annotation_map_tile(zoom = 7, cachedir = system.file("rosm.cache", package = "ggspatial"))  + # Enabled by "rosm" library
  
  # b. Zambia wards
  geom_sf(data = zambia_wards.sf, color = 'gray26', aes(fill = namelegend), size = 0.4) + 
  
  # c. Towers/Poles
  geom_sf(data = towers.sf, size = 3, shape = 21, aes(fill = namelegend), stroke = 0.3) +
  
  # d. Substationts
  geom_sf(data = substations.sf, size = 8, shape = 21, aes(fill = namelegend), stroke = 0.3) +
  
  # e. Schools
  geom_sf(data = schools.sf, size = 3, color = 'gray26', shape = 21, aes(fill = powersourcelegend), stroke = 0.08) +
  
  # f. Adding Arrow & Scale 
  annotation_scale(location = "br", width_hint = 0.25, pad_x = unit(0.25, "in"), pad_y = unit(0.35, "in")) +
  annotation_north_arrow(location = "br", which_north = "true", pad_x = unit(1.2, "in"), pad_y = unit(0.70, "in"), style = north_arrow_minimal) + # north_arrow_fancy_orienteering, north_arrow_minimal, north_arrow_nautical, 
  
  # g. Legend
  guides(fill=guide_legend(title="Legend")) +
  scale_fill_manual(name = "EMIS schools Electricity Status", 
                    values = c("grid (EMIS School Electricity Status)" = "darkseagreen4", 
                               "no grid (EMIS School Electricity Status)" = alpha("white",0),
                               "OSM Overpass Substations 2021" = alpha("goldenrod",0.5), 
                               "OSM Overpass Towers/Poles 2021" = alpha("lightskyblue3",0.5),
                               "Zambia Wards 2017"=alpha("gray94",0.7))
  ) +
  
  # h. Metadata
  ggtitle("Zambia Electricity Substations, Poles and EMIS Schools") +
  theme(legend.position = c(0.75, 0.15), legend.justification = c(0, 0), # Use legend.position to manually position legend; theme(legend.position = "none") -> Remove legend
        plot.margin = unit(c(0, 0.33, 0,0), "in") # Manually add margin
  )

# SAVE
plotwidth = 12
plotheight = 10.5
plotunit = "in"

ggsave("substation_info/OSM-Overpass_with_substations_EMIS.pdf", device = "pdf", width = plotwidth, height = plotheight, unit = plotunit)





