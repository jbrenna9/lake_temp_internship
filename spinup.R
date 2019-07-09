d = NULL
i=1
for(i in 1:100){

  glm_nml <- set_nml(glm_nml, arg_list = list('start' = dates[[1]][[4*i]],'stop' =  '1980-02-10 00:00:00'))
  write_nml(glm_nml, file = 'sim_raw/glm2.nml')
  sim_out = run_simulation(config_path = 'glm_nml',
                         orig_meteo_file = 'mendota_driver_data.csv',
                         meteo_file = sprintf('%s_meteo.csv', nhd_id),
                         meteo_dir = '1_data/in')

  temps <- get_temp(file.path('sim_raw', 'output.nc'), reference = 'surface', z_out = c(2,8,16))
  temps_target <- temps[which(temps$DateTime == '1980-02-10'), ]
  temps_target$index = dates[[1]][[4*i]]
  d = rbind(d, temps_target)
}
##Varying With Depth? - less deep less spinup required, on the other hand deeper temps are less volatile
#2 depth first ~73 predictions above 18, 8 depth first ~24 predictions above 18, 16 depth only first 7 above 10

f = NULL
for(i in 1:100){     ## breakdown at 4/28 not sure why -> very close to first temp obs 4/30

  glm_nml <- set_nml(glm_nml, arg_list = list('start' = dates[[1]][[75 + 4*i]],'stop' =  '1980-04-30 00:00:00'))
  write_nml(glm_nml, file = 'sim_raw/glm2.nml')
  sim_out = run_simulation(config_path = 'glm_nml',
                           orig_meteo_file = 'mendota_driver_data.csv',
                           meteo_file = sprintf('%s_meteo.csv', nhd_id),
                           meteo_dir = '1_data/in')

  temps <- get_temp(file.path('sim_raw', 'output.nc'), reference = 'surface', z_out = c(2,8,16))
  temps_target <- temps[which(temps$DateTime == '1980-04-30'), ] #breakdown here
  temps_target$index = dates[[1]][[75 + 4*i]]
  f = rbind(f, temps_target)
}

