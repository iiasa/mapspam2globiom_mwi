#'========================================================================================================================================
#' Project:  crop_map
#' Subject:  Code to select ESA land cover map per country
#' Author:   Michiel van Dijk
#' Contact:  michiel.vandijk@wur.nl
#'========================================================================================================================================

### PACKAGES
if(!require(pacman)) install.packages("pacman")
# Key packages
p_load("tidyverse", "readxl", "stringr", "scales", "RColorBrewer", "rprojroot")
# Spatial packages
p_load("rgdal", "ggmap", "raster", "rasterVis", "rgeos", "sp", "mapproj", "maptools", "proj4", "gdalUtils")
# Additional packages
p_load("WDI", "countrycode", "plotKML", "sf")


### SET ROOT AND WORKING DIRECTORY
root <- find_root(is_rstudio_project)


### R SETTINGS
options(scipen=999) # surpress scientific notation
options("stringsAsFactors"=FALSE) # ensures that characterdata that is loaded (e.g. csv) is not turned into factors
options(digits=4)


### SOURCE FUNCTIONS
source(file.path(root, "Code/general/support_functions.r"))


### LOAD DATA
# adm
adm <- readRDS(file.path(proc_path, paste0("maps/adm/adm_", year_sel, "_", iso3c_sel, ".rds")))


### TO_UPDATE: turn this into a function
### CLIP COUNTRY
temp_path <- file.path(proc_path, paste0("maps/esa"))
dir.create(temp_path, recursive = T, showWarnings = F)

input <-file.path(glob_path, paste0("ESA/ESACCI-LC-L4-LCCS-Map-300m-P1Y-", year_sel, "-v2.0.7.tif"))
input_shp <- file.path(proc_path, paste0("maps/adm/adm_", year_sel, "_", iso3c_sel, ".shp"))
output <- file.path(temp_path, paste0("esa_raw_", year_sel, "_", iso3c_sel, ".tif"))

message("Clip esa map")
esa <- gdalwarp(cutline =input_shp, crop_to_cutline = T, srcfile = input, dstfile = output, verbose = T, output_Raster = T, overwrite = T)


### CLEAN UP
rm(temp_path, input, input_shp, output, esa, adm)