# running GLM model example

library(glmtools)

source('2_model_glm/src/run_glm.R') # sourcing function for running glm simulation

nhd_id = 'nhd_13293262' # Lake Mendota's nhd ID

mod_nml <- function(nml, arg_n, arg_v){

  glm_nml <- read_nml(file.path(nml))
  glm_nml <- set_nml(glm_nml, arg_n, arg_v)
  write_nml(glm_nml, file = nml_file)

}

mod_nml('.sim_raw/glm2.nml', 'stop', '1995-12-30 00:00:00')

sim_out = run_simulation(config_path = 'glm_nml',
                         orig_meteo_file = 'mendota_driver_data.csv',
                         meteo_file = sprintf('%s_meteo.csv', nhd_id),
                         meteo_dir = '1_data/in')

glmtools::plot_temp(sim_out$ncpath)

field_file <- file.path('1_data', 'in', 'mendota_temp_obs.csv')

temp_rmse <- compare_to_field(sim_out$ncpath, field_file,
                                  metric = 'water.temperature', as_value = FALSE)
thermo <- compare_to_field(sim_out$ncpath, field_file,
                              metric = 'thermo.depth', as_value = TRUE)

temp <- resample_to_field(nc_file = '.sim_raw/output.nc', field_file = '1_data/in/mendota_temp_obs.csv')


#'glm_nml <- read_nml()
#'write_path <- paste0(tempdir(),'glm2.nml')
#'write_nml(glm_nml, file = write_path)
#'print(read_nml(write_path))
