##########################################################
## The following uses renv to help with reproducibility ##
##########################################################

# Uncomment the codes in this section if you would like to use it with your
# Check if renv is installed and load it
# if (!require("renv", character.only = TRUE)) {
#   install.packages("renv")
#   library("renv", character.only = TRUE)
# }

# Initialize renv and restore packages from the lockfile
# renv::init()
# renv::restore()

#############################################
## The following loads the needed packages ##
#############################################

# load your virtual environment for the project

# Load the required packages
packages <- c(
  # Project organization
  "here",
  
  # Data wrangling
  "tidyverse", "lubridate", "dplyr", "tidyr",
  
  # Plotting
  "patchwork", "maps", "scales", "ggmap", "ggplot2", "plotly", "ggrepel", "viridis",
  
  # Reporting
  "knitr", "kableExtra", "rmarkdown", "flextable",

  # Interactive tables
  "reactable",
  
  # Reading Excel files
  "readxl",
  
  # Clustering
  "cluster", "dendextend", "factoextra",
  
  # JSON handling
  "jsonlite",
  
  # Text analysis
  "quanteda", "quanteda.textstats", "quanteda.textplots", 
  "quanteda.textmodels","tidytext", 
  "stringr", "tm", "wordcloud", "SnowballC", "stopwords", 
  "ggwordcloud", "broom", "igraph", "reshape2",
  
  # Data splitting
  "caTools",
  
  # Topic modeling
  "topicmodels", "seededlda", "topicmodels", "topicdoc",
  
  "lexicon",
  
  #ML
  "textrecipes", "rsample", "tune", "workflows", "parsnip", "yardstick", "recipes"
)



# Install missing packages and load all the required libraries
purrr::walk(packages, function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
})

########################################
## The following sets the python path ##
########################################
#library(reticulate)
#use_python("C:/Python312/python.exe")
#py_config()
# reticulate::use_condaenv("NAME_OF_YOUR_ENVIRONMENT")


######################################################
## The following sets a few option for nice reports ##
######################################################

# general options
options(
  digits = 3,
  str = strOptions(strict.width = "cut"),
  width = 69,
  tibble.width = 69,
  cli.unicode = FALSE
)

# ggplot options
theme_set(theme_light())

# knitr options
knitr::opts_chunk$set(
  comment = "#>",
  collapse = TRUE,
  # cache = TRUE,
  fig.retina = 0.8, # figures are either vectors or 300 dpi diagrams
  dpi = 300,
  out.width = "70%",
  fig.align = "center",
  fig.width = 10,
  fig.height = 8,
  fig.asp = 0.618,
  fig.show = "hold",
  message = FALSE,
  echo = TRUE
)


