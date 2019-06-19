run_simulation <- function(config_path, orig_meteo_file, meteo_file, meteo_dir){


  sim_dir <- '.sim_raw'
  nml_sim_path <- file.path(sim_dir, 'glm2.nml')
  file.copy(from = config_path, to = nml_sim_path, overwrite = TRUE)
  nml <- read_nml(nml_sim_path)
  meteopath <- file.path(sim_dir, meteo_file)
  ncpath <- file.path(sim_dir, paste0(get_nml_value(nml, 'out_fn'), '.nc'))
  diagpath <- file.path(sim_dir, paste0(get_nml_value(nml, 'csv_lake_fname'),'.csv'))


  write_nml(glm_nml = nml, file = nml_sim_path)
  drivers <- read.csv(file.path(meteo_dir, orig_meteo_file))

  write.csv(drivers, file = meteopath, row.names=FALSE, quote=FALSE)
  run_glm(sim_dir)
  return(list(ncpath = ncpath,
              nmlpath = nml_sim_path,
              meteopath = meteopath,
              diagpath = diagpath,
              simhash = unname(tools::md5sum(ncpath))) # hash for sim so we know it has changed
  )

}

# run_simulation <- function(config_path, orig_meteo_file, meteo_file, meteo_dir, start, stop, add_rain, burnin_years){
#
#
#   sim_dir <- '.sim_raw'
#   nml_sim_path <- file.path(sim_dir, 'glm2.nml')
#   file.copy(from = config_path, to = nml_sim_path, overwrite = TRUE)
#   nml <- read_nml(nml_sim_path)
#   meteopath <- file.path(sim_dir, meteo_file)
#   ncpath <- file.path(sim_dir, paste0(get_nml_value(nml, 'out_fn'), '.nc'))
#   diagpath <- file.path(sim_dir, paste0(get_nml_value(nml, 'csv_lake_fname'),'.csv'))
#
#   # setting start / stop if supplied
#   start_nml = start
#   if(!is.null(start)){
#     if(burnin_years > 0){
#       start_nml = as.POSIXct(start) - as.difftime(burnin_years * 365, units='days')
#     }
#     nml <- set_nml(nml, arg_name = 'start', arg_val = paste(start_nml, '00:00:00'))
#   }
#   if(!is.null(start)){
#     nml <- set_nml(nml, arg_name = 'stop', arg_val = paste(stop, '00:00:00'))
#   }
#
#   write_nml(glm_nml = nml, file = nml_sim_path)
#
#   # read in drivers and adding burnin and rain if indicated
#   drivers <- read.csv(file.path(meteo_dir, orig_meteo_file))
#   if(add_rain){
#     drivers <- mda.lakes::driver_add_rain(drivers = drivers)
#   }
#   if(burnin_years >0){
#     if(!is.null(start)){
#       drivers <- dplyr::filter(drivers, as.POSIXct(time) >= as.POSIXct(start))
#       drivers <- mda.lakes::driver_add_burnin_years(drivers = drivers)
#     }
#     drivers <- mda.lakes::driver_add_burnin_years(drivers = drivers)
#   }
#
#
#   write.csv(drivers, file = meteopath, row.names=FALSE, quote=FALSE)
#   run_glm(sim_dir)
#   # out = list(ncpath = ncpath,
#   #             nmlpath = nml_sim_path,
#   #             meteopath = meteopath,
#   #             diagpath = diagpath,
#   #             simhash = unname(tools::md5sum(ncpath))) # hash for sim so we know it has changed
#   #
#   # saveRDS(out, f)
#
# }
#
