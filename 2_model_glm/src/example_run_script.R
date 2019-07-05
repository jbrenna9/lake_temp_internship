# running GLM model example

library(glmtools)

source('2_model_glm/src/run_glm.R') # sourcing function for running glm simulation

nhd_id = 'nhd_13293262' # Lake Mendota's nhd ID


start = '2010-04-01' #start of simulation
stop = '2011-10-01' # end of simulation
add_rain = T # adding rain so that lake level stays the same
burnin_years = 4 # adding burnin time period so that model stabilizes

sim_param_list <- list('start' = '1979-01-02 24:00:00','stop' = '1979-01-04 00:00:00')

EnStep <- function()

glm_nml <- set_nml(glm_nml, arg_list = list('start' = '1979-01-02 24:00:00','stop' = '1980-12-04 00:00:00'))
write_nml(glm_nml, file = 'sim_raw/glm2.nml')
sim_out = run_simulation(config_path = 'glm_nml',
                         orig_meteo_file = 'mendota_driver_data.csv',
                         meteo_file = sprintf('%s_meteo.csv', nhd_id),
                         meteo_dir = '1_data/in')


nc_file <- file.path('sim_raw', 'output.nc')


glmtools::plot_temp(sim_out$ncpath)


field_file <- file.path('1_data', 'in', 'mendota_temp_obs.csv')

temp_rmse <- compare_to_field(sim_out$ncpath, field_file,
                                  metric = 'water.temperature', as_value = FALSE)
thermo <- compare_to_field(sim_out$ncpath, field_file,
                              metric = 'ShortWave', as_value = TRUE)

temp <- resample_to_field(nc_file = 'sim_raw/output.nc', field_file = '1_data/in/mendota_temp_obs.csv')


#'glm_nml <- read_nml()
#'write_path <- paste0(tempdir(),'glm2.nml')
#'write_nml(glm_nml, file = write_path)
#'print(read_nml(write_path))

