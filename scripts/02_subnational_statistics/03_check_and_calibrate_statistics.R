#'========================================================================================================================================
#' Project:  mapspam2globiom
#' Subject:  Script to check and calibrate subnational statistics
#' Author:   Michiel van Dijk
#' Contact:  michiel.vandijk@wur.nl
#'========================================================================================================================================

############### SOURCE PARAMETERS ###############
source(here::here("scripts/01_model_setup/01_model_setup.r"))


############### LOAD DATA ###############
# harvest area statistics
ha_df_raw <- read_csv(file.path(param$raw_path,
  glue("subnational_statistics/subnational_harvested_area_{param$year}_{param$iso3c}.csv")))

# Farming systems shares
fs_df_raw <- read_csv(file.path(param$raw_path,
  glue("subnational_statistics/farming_system_shares_{param$year}_{param$iso3c}.csv")))

# Cropping intensity
ci_df_raw <- read_csv(file.path(param$raw_path,
  glue("subnational_statistics/cropping_intensity_{param$year}_{param$iso3c}.csv")))

# adm_list
load_data("adm_list", param)

# faostat
fao_raw <- read_csv(file.path(param$spam_path,
  glue("processed_data/agricultural_statistics/faostat_crops_{param$year}_{param$iso3c}.csv")))


############### PROCESS HA STATISTICS ###############
# wide to long format
ha_df <- ha_df_raw %>%
  gather(crop, ha, -adm_name, -adm_code, -adm_level)

# Convert -999 and empty string values to NA
ha_df <- ha_df %>%
  mutate(ha = if_else(ha == -999, NA_real_, ha),
         ha = as.numeric(ha)) # this will transform empty string values "" into NA and throw a warning

# filter out crops which values are all zero or NA
crop_na_0 <- ha_df %>%
  group_by(crop) %>%
  filter(all(ha %in% c(0, NA))) %>%
  dplyr::select(crop) %>%
  unique

ha_df <- ha_df %>%
  filter(!crop %in% crop_na_0$crop)

# Remove lower level adm data if it would in the data but not used
ha_df <- ha_df %>%
  filter(adm_level <= param$adm_level)

# Round values
ha_df <- ha_df %>%
  mutate(ha = round(ha, 0))

# Check if the statistics add up and show where this is not the case
check_statistics(ha_df, param, out = T)

# Make sure the totals at higher levels are the same as subtotals
# We start at the lowest level, assuming lower levels are preferred if more than one level
# of data is available and data is complete.
ha_df <- reaggregate_statistics(ha_df, param)

# Check again
check_statistics(ha_df, param, out = T)


########## HARMONIZE HA WITH FAOSTAT ##########
# Compare with FAO
# Process fao
fao <- fao_raw %>%
  filter(year %in% c((param$year-1): (param$year+1))) %>%
  group_by(crop) %>%
  summarize(ha = mean(value, na.rm = T)) %>%
  dplyr::select(crop, ha)

# Compare
fao_ha <- bind_rows(
  fao %>%
    mutate(source = "fao"),
  ha_df %>%
    filter(adm_level == 0) %>%
    mutate(source = "ha_df")
)

ggplot(data = fao_ha) +
  geom_col(aes(x = source, y = ha, fill = source)) +
  facet_wrap(~crop, scales = "free")

# We scale all the data to FAOSTAT
# If the data is incomplete and the sum is lower than FAOSTAT we do no adjust.
# If the data is incomplete and the sum is higher than FAOSTAT we scale down.

# Identify crops that are present in ha_df but not in fao and remove them from ha_df.
crop_rem <- setdiff(unique(ha_df$crop), unique(fao$crop))
ha_df <- ha_df %>%
  filter(!crop %in% crop_rem)

# Identify crops that are present in fao but not in ha_df.
# We will add then to ha_df
crop_add <- setdiff(unique(fao$crop), unique(ha_df$crop))
ha_df <- ha_df %>%
  bind_rows(
    fao %>%
      filter(crop %in% crop_add) %>%
      mutate(
        fips = unique(ha_df$adm_code[ha_df$adm_level==0]),
        adm_level = 0,
        adm = unique(ha_df$adm_name[ha_df$adm_level==0])))


# Calculate scaling factor
fao_stat_sf <-bind_rows(
  fao %>%
    mutate(source = "fao"),
  ha_df %>%
    filter(adm_level == 0) %>%
    mutate(source = "ha_df")) %>%
  dplyr::select(crop, source, ha) %>%
  spread(source, ha) %>%
  mutate(sf = fao/ha_df) %>%
  dplyr::select(crop, sf)

# rescale ha_df
ha_df <- ha_df %>%
  left_join(fao_stat_sf) %>%
  mutate(ha = ha * sf) %>%
  dplyr::select(-sf)

# Compare again
fao_stat <- bind_rows(
  fao %>%
    mutate(source = "fao"),
  ha_df %>%
    filter(adm_level == 0) %>%
    mutate(source = "ha_df")
)

ggplot(data = fao_stat) +
  geom_col(aes(x = source, y = ha, fill = source)) +
  facet_wrap(~crop, scales = "free")


############### FINALIZE HA ###############
# Consistency checks
check_statistics(ha_df, param)

# To wide format
ha_df <- ha_df %>%
  spread(crop, ha, fill = -999) %>%
  arrange(adm_code, adm_name, adm_level)


############### PROCESS FARMING SYSTEM SHARES ###############
# ci does not need to be adjusted
fs_df <- fs_df_raw


############### PROCESS CROPPING INTENSITY ###############
# ci does not need to be adjusted
ci_df <- ci_df_raw


########## SAVE ##########
# Save the ha, fs and ci csv files in the Processed_data/agricultural_statistics folder
# Note that they have to be saved in this folder using the names below so do not change this!
write_csv(ha_df, file.path(param$spam_path, glue("processed_data/agricultural_statistics/ha_adm_{param$year}_{param$iso3c}.csv")))
write_csv(fs_df, file.path(param$spam_path, glue("processed_data/agricultural_statistics/fs_adm_{param$year}_{param$iso3c}.csv")))
write_csv(ci_df, file.path(param$spam_path, glue("processed_data/agricultural_statistics/ci_adm_{param$year}_{param$iso3c}.csv")))


############### NOTE ###############
# As you probably created a lot of objects in he R memory, we recommend to
# restart R at this moment and start fresh. This can be done easily in RStudio by
# pressing CTRL/CMD + SHIFT + F10.
