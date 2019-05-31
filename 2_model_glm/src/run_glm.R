
run_simulation <- function(config_path, meteo_file, driver_data){


  sim_dir <- '.sim_raw'
  nml_sim_path <- file.path(sim_dir, 'glm2.nml')
  file.copy(from = config_path, to = nml_sim_path, overwrite = TRUE)
  nml <- read_nml(nml_sim_path)
  meteopath <- file.path(sim_dir, meteo_file)
  ncpath <- file.path(sim_dir, paste0(get_nml_value(nml, 'out_fn'), '.nc'))
  diagpath <- file.path(sim_dir, paste0(get_nml_value(nml, 'csv_lake_fname'),'.csv'))


  write_nml(glm_nml = nml, file = nml_sim_path)
  drivers <- feather::read_feather(driver_data)

  write.csv(drivers, file = meteopath, row.names=FALSE, quote=FALSE)
  run_glm(sim_dir)
  return(list(ncpath = ncpath,
              nmlpath = nml_sim_path,
              meteopath = meteopath,
              diagpath = diagpath,
              simhash = unname(tools::md5sum(ncpath))) # hash for sim so we know it has changed
  )

}

