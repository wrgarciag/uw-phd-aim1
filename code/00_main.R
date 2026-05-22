rm(list=ls()) 

#libraries
library(dplyr)
library(data.table)
library(tidyr)
library(ggplot2)
library(RColorBrewer)
library(readxl)   
library(countrycode)
library(stringr)
library(parallel)
library(doParallel)
library(foreach)
library(gmodels)

# Main directory for the project with GitHub repository - change to your local path
wd <- "C:/Users/wrgar/OneDrive - UW/04Dissertation/uw-phd-aim1/"

wd_code <- paste0(wd,"code/")

# Raw data not available on GitHub
wd_raw <- paste0(wd,"data/raw/")

# Processed data (from base rates and tps)
wd_data <- paste0(wd,"data/processed/")
wd_outp <- paste0(wd,"output/")

# Create a temporary directory for the processing data change to wd in final version
wd_temp <- paste0("C:/Users/wrgar/OneDrive - UW/04Dissertation/","temp/")
if (!dir.exists(wd_temp)) {
  dir.create(wd_temp, recursive = TRUE)
}

setwd(wd_code)

#...........................................................
# 01. Functions and parameters-----
#...........................................................

source("01_utils.R")

#...........................................................
# 02. Load inputs-----
#...........................................................

source("02_load_inputs.R")

#...........................................................
# 03. ppd estimation and trends-----
#...........................................................

source("03_ppd_estimation_trends_state.R")

#...........................................................
# 04. define interventions ----
#...........................................................

source("04_ppd_decomposition_state_cause.R")
