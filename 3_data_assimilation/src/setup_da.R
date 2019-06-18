# example for Data Assimilation


# set up for ensembles
nEn = 100 # number of ensembles
nStep = as.numeric(as.difftime(as.POSIXct(stop) - as.POSIXct(start), units = 'days')) # model time steps


# set up initial conditions; make draws for parameters, states,

# means, mins, maxs
params = dplyr::tibble(param = c('cd', 'ce', 'ch', 'coef_wind_stir', 'coef_mix_conv', 'sw_factor', 'at_factor', 'rh_factor'),
                     mean = c(0.0013, 0.0013, 0.0013, 0.23, 0.2, 1, 1, 1),
                     min = c(0.0001, 0.0001, 0.0001, 0.01, 0.01, 0.8, 0.8, 0.8),
                     max = c(0.01, 0.01, 0.01, 0.4, 0.4, 1.2, 1.2, 1.2))

# pdf's
init_params = lapply(params$param, function(param, mean, min, max){
  pdf = abs(rnorm(n = nEn,
              mean = params$mean[params$param == param],
              sd = (params$max[params$param == param] - params$min[params$param == param]) / 5))
}) %>% dplyr::bind_cols() %>% 'colnames<-'(params$param)



# inputs to ensemble Kalman filter

Y # holds all states and parameters
ensemble
time_step

# need to:
#   1) calculate difference in ensemble states/parametrs and mean of each ensemble state/parameter
#   2) calculate Kalman gain
#   3) Update Y vector with Kalman gain
#   4) Update GLM state and parameters with updated Y vector

for(i in 1:nEn){
  # run simulation for given ensemble


  # update Y vector with sim output

}




