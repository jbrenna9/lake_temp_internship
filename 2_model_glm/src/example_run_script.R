# running GLM model example

library(glmtools)

source('2_model_glm/src/run_glm.R') # sourcing function for running glm simulation

nhd_id = 'nhd_13293262' # Lake Mendota's nhd ID

sim_out = run_simulation(config_path = '2_model_glm/cfg/Mendota_glm_config.txt',
                         orig_meteo_file = 'mendota_driver_data.csv',
                         meteo_file = sprintf('%s_meteo.csv', nhd_id),
                         meteo_dir = '1_data/in')

glmtools::plot_temp(sim_out$ncpath)
