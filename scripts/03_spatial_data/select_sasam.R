#'========================================================================================================================================
#' Project:  mapspam2globiom
#' Subject:  Code process SASAM global synergy cropland map
#' Author:   Michiel van Dijk
#' Contact:  michiel.vandijk@wur.nl
#'========================================================================================================================================

############### SOURCE PARAMETERS ###############
source(here::here("scripts/01_model_setup/01_model_setup.r"))


############### PROCESS CROPRATIO (MEDIAN AREA) ###############
temp_path <- file.path(param$spam_path, glue("processed_data/maps/cropland/{param$res}"))
dir.create(temp_path, showWarnings = FALSE, recursive = TRUE)


# Set files
grid <- file.path(param$spam_path,
                  glue("processed_data/maps/grid/{param$res}/grid_{param$res}_{param$year}_{param$iso3c}.tif"))
mask <- file.path(param$spam_path,
                  glue("processed_data/maps/adm/{param$res}/adm_map_{param$year}_{param$iso3c}.shp"))
input <- file.path(param$spam_path,
                   glue("raw_data/sasam/{param$continent}/cropland_ratio_{param$continent}.tif"))
output <- file.path(param$spam_path,
                    glue("processed_data/maps/cropland/{param$res}/cl_med_share_{param$res}_{param$year}_{param$iso3c}.tif"))

# Warp and mask
output_map <- align_rasters(unaligned = input, reference = grid, dstfile = output,
                            cutline = mask, crop_to_cutline = F,
                            r = "bilinear", verbose = F, output_Raster = T, overwrite = T)

# Maps are in shares of area. We multiply by grid size to create an area map.
a <- area(output_map)
output_map <- output_map * a * 100
plot(output_map)
writeRaster(output_map, file.path(param$spam_path,
  glue("processed_data/maps/cropland/{param$res}/cl_med_{param$res}_{param$year}_{param$iso3c}.tif")),overwrite = T)

# clean up
rm(grid, input, mask, output, output_map)


############## PROCESS CROPMAX (MAXIMUM AREA) ###############
# Set files
grid <- file.path(param$spam_path,
                  glue("processed_data/maps/grid/{param$res}/grid_{param$res}_{param$year}_{param$iso3c}.tif"))
mask <- file.path(param$spam_path,
                  glue("processed_data/maps/adm/{param$res}/adm_map_{param$year}_{param$iso3c}.shp"))
input <- file.path(param$spam_path,
                   glue("raw_data/sasam/{param$continent}/cropland_max_{param$continent}.tif"))
output <- file.path(param$spam_path,
                    glue("processed_data/maps/cropland/{param$res}/cl_share_{param$res}_{param$year}_{param$iso3c}.tif"))

# warp and mask
output_map <- align_rasters(unaligned = input, reference = grid, dstfile = output,
                            cutline = mask, crop_to_cutline = F,
                            r = "bilinear", verbose = F, output_Raster = T, overwrite = T)

# Maps are in shares of area. We multiply by grid size to create an area map.
a <- area(output_map)
output_map <- output_map * a * 100
plot(output_map)
writeRaster(output_map, file.path(param$spam_path,
                             glue("processed_data/maps/cropland/{param$res}/cl_max_{param$res}_{param$year}_{param$iso3c}.tif")),overwrite = T)

# clean up
rm(a, grid, input, mask, output, output_map)


############### PROCESS CROPPROB (PROBABILITY, 1 IS HIGHEST) ###############
# Set files
grid <- file.path(param$spam_path,
                      glue("processed_data/maps/grid/{param$res}/grid_{param$res}_{param$year}_{param$iso3c}.tif"))
mask <- file.path(param$spam_path,
                  glue("processed_data/maps/adm/{param$res}/adm_map_{param$year}_{param$iso3c}.shp"))
input <- file.path(param$spam_path,
                   glue("raw_data/sasam/{param$continent}/cropland_confidence_level_{param$continent}.tif"))
output <- file.path(param$spam_path,
                    glue("processed_data/maps/cropland/{param$res}/cl_rank_{param$res}_{param$year}_{param$iso3c}.tif"))

# warp and mask
# Use r = "med" to select the median probability as probability is a categorical variable (1-32).
# Remove 0 values (no cropland) before processing as they will bias taking the medium value.
output_map <- align_rasters(unaligned = input, reference = grid, dstfile = output,
                            cutline = mask, crop_to_cutline = F, srcnodata = "0",
                            r = "med", verbose = F, output_Raster = T, overwrite = T)
plot(output_map)

# clean up
rm(grid, input, mask, output, output_map, temp_path)




