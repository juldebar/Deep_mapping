#######################
# install.packages("pacman")
pacman::p_load(remotes,geoflow,googledrive, exifr, RPostgreSQL, rgdal, data.table,dplyr,trackeR,lubridate,pdftools,rosm,gsheet,dplyr,sf)
# install.packages("remotes")
require("remotes")
install_github("eblondel/geoflow", dependencies = c("Depends", "Imports"))
#######################
##Database Identifiers:
Dbname ="Reef_database"
User="user_admin"
Password="my_password"
Host="reef-db.d4science.org"
DRV="PostgreSQL"
#######################
#######################
##Database Identifiers:
Dbname ="Reef_database"
User="postgres"
Password="my_password"
Host="localhost"
DRV="PostgreSQL"
#######################
codes_directory <-"~/Desktop/CODES/Deep_mapping/"
setwd(codes_directory)
source(paste0(codes_directory,"R/credentials_databases.R"))
codes_github_repository <-"https://raw.githubusercontent.com/juldebar/Deep_mapping/master/"
setwd(codes_directory)
images_directory <- "/home/julien/Desktop/Data/Data_Deep_Mapping"
#######################
#specify here which google drive folders should be used to store files
google_drive_path <- drive_get(id="1tZrN_zKxhc6Q0ysUp8XEbTnID6HCV13K")
google_drive_file_url <- paste0("https://drive.google.com/open?id=",google_drive_path$id)
# DCMI_metadata_google_drive_path <- drive_get(id="12anx6McwA6xiZeswfF8Y9sGuQSnohWZsUNIhc1fFjnw")
DCMI_metadata_google_drive_path <- drive_get(id="1tZrN_zKxhc6Q0ysUp8XEbTnID6HCV13K")
tags_folder_google_drive_path <- drive_get(id="1U6I6tgAqKRDgurb7gnQGV8Q5_i_jJSB4")
tags_file_google_drive_path <- drive_get(id="1eFJq003Z3JayIHtgupYfM01qV2IVT3VuBeYt6a0OKdM")
#######################