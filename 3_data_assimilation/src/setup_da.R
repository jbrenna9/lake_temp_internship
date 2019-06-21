# example for Data Assimilation

library(glmtools)
library(dplyr)

###############################################################
# set up for ensembles
##############################################################
# start / end of simulation
start = '2010-06-01'
stop = '2010-10-01'

# important file paths and directories
obs_file_path = '1_data/in/mendota_temp_obs.csv'
driver_file_path = '1_data/in/mendota_driver_data.csv'
orig_nml_path = '2_model_glm/cfg/Mendota_glm_config.txt'
sim_dir = 'sim_raw'
meteo_file = 'nhd_13293262_meteo.csv'
hist_days = 365*2 # "spin-up" days

nEn = 1 # number of ensembles

################################################################
# set up initial conditions; make draws for parameters, states,
################################################################

# means, mins, maxs of parameters to optimize in EnKF
params = dplyr::tibble(param = c('cd', 'ce', 'ch', 'coef_wind_stir', 'coef_mix_conv', 'sw_factor', 'at_factor', 'rh_factor'),
                     mean = c(0.0013, 0.0013, 0.0013, 0.23, 0.2, 1, 1, 1),
                     min = c(0.0001, 0.0001, 0.0001, 0.01, 0.01, 0.8, 0.8, 0.8),
                     max = c(0.01, 0.01, 0.01, 0.4, 0.4, 1.2, 1.2, 1.2))

# pdf's of parameters
init_params = lapply(params$param, function(param, mean, min, max){
  pdf = abs(rnorm(n = nEn,
              mean = params$mean[params$param == param],
              sd = 0))#(params$max[params$param == param] - params$min[params$param == param]) / 5)) # (max - min) / 5 is approximately equal to SD
}) %>% dplyr::bind_cols() %>% 'colnames<-'(params$param)


##################################################################
# set up initial nml with temperature from earliest observation
##################################################################
temp_obs = read.csv(obs_file_path, stringsAsFactors = F) %>%
  dplyr::filter(as.Date(DateTime) >= as.Date(start))

start = as.character(min(as.Date(temp_obs$DateTime))) # new start time based on earliest temp observation
nStep = as.numeric(as.difftime(as.POSIXct(stop) - as.POSIXct(start), units = 'days')) # model time steps
sim_times = as.character(seq.Date(as.Date(start)-hist_days, as.Date(stop), by = 'days'))

# pulling out initial temperatures and depths based on observations
init_temp_obs = temp_obs$temp[temp_obs$DateTime == start]
init_depth_obs = temp_obs$Depth[temp_obs$DateTime == start]
n_depths = length(init_depth_obs)
init_sal = rep(0, n_depths) # setting salinity to 0

# copy over original nml file to simulation directory
dir.create(sim_dir, showWarnings = F) # creating simulation directory
sim_nml = file.path(sim_dir, 'glm2.nml')
file.copy(from = orig_nml_path, to = sim_nml, overwrite = TRUE) # copying over original Mendota nml/configuration file


##########################################################################
# Example of update initial temp observations and depths in nml file
# nml = glmtools::read_nml(sim_nml)
# nml = glmtools::set_nml(glm_nml = nml, arg_list = list('start' = start,
#                                                        'stop' = stop,
#                                                        'the_depths' = init_depth_obs,
#                                                        'the_temps' = init_temp_obs,
#                                                        'num_depths' = n_depths,
#                                                        'the_sals' = init_sal,
#                                                        'meteo_fl' = meteo_file,
#                                                        'cd' = params$mean[params$param == 'cd'],
#                                                        'ce' = params$mean[params$param == 'ce'],
#                                                        'ch' = params$mean[params$param == 'ch'],
#                                                        'coef_wind_stir' = params$mean[params$param == 'coef_wind_stir'],
#                                                        'coef_mix_conv' = params$mean[params$param == 'coef_mix_conv'],
#                                                        'sw_factor' = params$mean[params$param == 'sw_factor'],
#                                                        'at_factor' = params$mean[params$param == 'at_factor'],
#                                                        'rh_factor' = params$mean[params$param == 'rh_factor']))
# glmtools::write_nml(glm_nml = nml, file = sim_nml) #write out modified nml
#
# run_glm(sim_dir)
# glmtools::plot_temp('sim_raw/output.nc')
#####################################################################################


# inputs to ensemble Kalman filter
state_temp_depths = c(1,2,4,6,8,10,12,16,20) # depths for which we are keeping track in Y vector (for comparing to observations)
n_states = length(state_temp_depths)
n_params = length(params$param)

# holds all states and parameters for all ensembles at all time steps; dimensions are Y[state_or_parameter, ensemble, time_step]
Y = list(states = array(NA,  c(n_states, nEn, nStep)),
         params = array(NA,  c(n_params, nEn, nStep)))

####################
# observation error and initial states
####################
temp_obs_sd = 0.5 # this is just a guess right now; in the future, we should base this on sensor specs and our best guess at depth error
init_temps = lapply(state_temp_depths, function(depth){
  cur_temp = rnorm(n = nEn, mean = init_temp_obs[init_depth_obs == depth], sd = temp_obs_sd)
}) %>% dplyr::bind_cols()


#######################################################
# set up Y vector with initial conditions
#######################################################
for(i in 1:n_states){
  Y$states[i, , 1] = as.matrix(init_temps[, i])
}
for(i in 1:n_params){
  Y$params[i, , 1] = as.matrix(init_params[, i])
}


# for the EnKF we need to:
#   1) calculate difference in ensemble states/parametrs and mean of each ensemble state/parameter
#   2) calculate Kalman gain
#   3) Update Y vector with Kalman gain
#   4) Update GLM state and parameters with updated Y vector

for(t in 2:nStep){

  cur_start = sim_times[t]
  cur_stop = sim_times[t + hist_days + 1]

  for(i in 1:nEn){
    print(c(paste('time step', t, ','), paste('ensemble', i)))
    # update the nml file with previous time step's information
    cur_states = Y$states[, i, t-1]
    cur_params = Y$params[, i, t-1]
    cur_sal = rep(0, n_states) # zero salinity for each depth we're modeling

    cur_nml = glmtools::read_nml(sim_nml)
    cur_nml = glmtools::set_nml(glm_nml = cur_nml, arg_list = list('start' = cur_start,
                                                           'stop' = cur_stop,
                                                           'the_depths' = state_temp_depths,
                                                           'the_temps' = cur_states,
                                                           'num_depths' = n_states,
                                                           'the_sals' = cur_sal,
                                                           'meteo_fl' = meteo_file,
                                                           'cd' = cur_params[1],
                                                           'ce' = cur_params[2],
                                                           'ch' = cur_params[3],
                                                           'coef_wind_stir' = cur_params[4],
                                                           'coef_mix_conv' = cur_params[5],
                                                           'sw_factor' = cur_params[6],
                                                           'at_factor' = cur_params[7],
                                                           'rh_factor' = cur_params[8]))

    # write the nml file
    glmtools::write_nml(glm_nml = cur_nml, file = sim_nml) #write out modified nml

    # run the simulation for given ensemble
    run_glm(sim_folder = sim_dir)

    temps_mod = glmtools::get_temp(file.path(sim_dir, 'output.nc'), reference = 'surface', z_out = state_temp_depths)

    # update Y vector with sim output

    Y$states[, i, t] = as.matrix(temps_mod[as.Date(temps_mod$DateTime) == as.Date(sim_times[t+hist_days]), 2:ncol(temps_mod)])
    # Y$params[, i, t] =
    Y$params[, i, t] = as.matrix(Y$params[, i, t-1])



    # check if there are observations to compare to


    # update states and parameters


  }
}

# visualize output
plot(Y$states[,1,], type= 'l' , lwd=0, col ='white' ,ylim = c(min(Y$states[,,]),max(Y$states[,,])))
for(d in 1:9){
  for(m in 1:nEn){
    lines(Y$states[d,m,], type= 'l' )
  }
}






