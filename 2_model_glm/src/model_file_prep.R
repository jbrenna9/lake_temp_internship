
get_driver_file <- function(filepath, nhd_id){
  temp_path <- mda.lakes::get_driver_path(nhd_id)

  drivers <- driver_add_rain(read_csv(temp_path), rain_add = 0.7)

  feather::write_feather(drivers, filepath)
}

# generate nml file for running GLM
get_nml_file <- function(filepath, nhd_id, meteopath, ...){

  nml <- mda.lakes::populate_base_lake_nml(site_id = nhd_id,
                                driver = meteopath)
  nml <- set_nml(nml, arg_list = list(...))
  nml$sed_heat <- NULL
  write_nml(glm_nml = nml, file = filepath)
}

