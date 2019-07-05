source('2_model_glm/src/run_glm.R')
nhd_id = 'nhd_13293262'
glm_nml <- read_nml('sim_raw/glm2.nml')


params = dplyr::tibble(param = c('cd', 'ce', 'ch', 'coef_wind_stir', 'coef_mix_conv', 'sw_factor', 'at_factor', 'rh_factor'),
                       mean = c(0.0013, 0.0013, 0.0013, 0.23, 0.2, 1, 1, 1),
                       min = c(0.0001, 0.0001, 0.0001, 0.01, 0.01, 0.8, 0.8, 0.8),
                       max = c(0.01, 0.01, 0.01, 0.4, 0.4, 1.2, 1.2, 1.2))
init_params = lapply(params$param, function(param, mean, min, max){
  pdf = abs(rnorm(n = nEn,
                  mean = params$mean[params$param == param],
                  sd = (params$max[params$param == param] - params$min[params$param == param]) / 5))
}) %>% dplyr::bind_cols() %>% 'colnames<-'(params$param)

param_list <- setNames(split(init_params, seq(nrow(init_params))), rownames(init_params))


temps_tibble <- read.csv('1_data/in/mendota_temp_obs.csv')


start_dates = paste(seq.Date(as.Date('1979-01-01'), as.Date('2010-01-01'), by = 'days'), '24:00:00')
stop_dates = paste(seq.Date(as.Date('1979-01-03'), as.Date('2010-01-03'), by = 'days'), '00:00:00')
dates = dplyr::tibble(start_dates = start_dates, stop_dates = stop_dates)


nEn = 100
nStep = 10
Y <- array(dim = c(17,nStep,nEn))


##Kalman loop?
for (i in 1:nStep){
  glm_nml <- set_nml(glm_nml, arg_list = list('start' = dates[[1]][440 + i], 'stop' = dates[[2]][481 + i]))
  write_nml(glm_nml, file = 'sim_raw/glm2.nml')

  for (j in 1:nEn){
    glm_nml <- set_nml(glm_nml, arg_list = param_list[[j]])
    write_nml(glm_nml, file = 'sim_raw/glm2.nml')
    sim_out = run_simulation(config_path = 'glm_nml',
                             orig_meteo_file = 'mendota_driver_data.csv',
                             meteo_file = sprintf('%s_meteo.csv', nhd_id),
                             meteo_dir = '1_data/in')

    temp_df <- get_temp(file.path('sim_raw', 'output.nc'), reference = 'surface', z_out = c(1,3,5,6,8,10,15,20))
    target_df <- temp_df[which(as.Date(temp_df$DateTime) == dates[[2]][481 + i]), ]  ## edit date
    tmp_vector <- c(as.numeric(target_df[1,]), as.numeric(init_params[j,]))
    Y[,i,j] <- tmp_vector
  }

  stop <- dates[[2]][481 + i]
  if (grepl(temps_tibble[,1][1], stop)){break}
}







