

export_temp <- function(outfile, simout, export_depths){

  temp_data <- get_temp(simout$ncpath, reference = 'surface', z_out = export_depths)

  feather::write_feather(temp_data, outfile)
}

export_shortwave <- function(outfile, simout){

  tmp_data <- get_var(simout$ncpath, "I_0")

  feather::write_feather(tmp_data, outfile)
}

export_energy <- function(outfile, simout){

  energy_data <- get_internal_energy(simout$ncpath)

  feather::write_feather(energy_data, outfile)
}


export_diagnostics <- function(outfile, simout){
  diag_data <- read.csv(simout$diagpath)
  diag_data$time <- as.POSIXct(diag_data$time, tz = 'UTC')
  feather::write_feather(diag_data, outfile)
}
export_session <- function(fileout){
  writeLines(capture.output(sessionInfo()), fileout)
}
