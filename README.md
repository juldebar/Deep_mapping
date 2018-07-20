This is a repository providing R codes to manage underwater pictures and their spatial location

In this repository we use: 
 - [exifr](https://www.r-bloggers.com/extracting-exif-data-from-photos-using-r/) package to extract exif metadata from JPG images
 - 
 
 
 Data collected have to comply with the following file structure:
 
<img style="position: absolute; top: 0; right: 0; border: 0;" src="http://mdst-macroes.ird.fr/BlueBridge/Ichtyop/Ichthyop_tree_structure.svg" width="500">

Our goal is to use this data structure as an input for R codes which will parse the subdirectories and files to load information in a Postgres / Postgis database with the following conceptual model:
 
<img style="position: absolute; top: 0; right: 0; border: 0;" src="https://drive.google.com/uc?id=1KTMUd6SQ9UGR3xMrtDYsAB0vNSYUlUZ5" width="500">


The main steps of the workflow are :
 - `extract` general metadata (~ Dublin Core) from google spreadsheet and load them in a dedicated table of the database
 - extract metadata from photos with exifr package and load them them in a dedicated table of the database
 - **extract** data from GPS tracks (txc or gpx files) and load them them in a dedicated table of the database
 - correlation of GPS timestamps and photos timestamps to infer photos locations (done with a SQL query / trigger in Postgis)
 
 
 
The file functions.R contains the following functions:
 - [extract_exif_metadata_in_csv]() 
 - [rename_exif_csv]() 
 - [return_dataframe_tcx_files]() 
 - [return_dataframe_csv_exif_metadata_files]() 
 - [sessions_metadata_dataframe]() 
 - [exifr]() 
 - [exifr]() 

## Set functions and connection details for Postgres / Postgis server (create your own "credentials_databases.R" file)

~~~~
###################################### LOAD SESSION METADATA ############################################################
source("/home/julien/Bureau/CODES/Deep_mapping/R/functions.R")
source("/home/julien/Bureau/CODES/credentials_databases.R")
~~~~

 
## CREATE Session Table in the Database and fill it with metadata stored in a google spreadsheet

~~~~
###################################### LOAD SESSION METADATA ############################################################
con_Reef_database <- dbConnect(DRV, user=User, password=Password, dbname=Dbname, host=Host)
query_create_table <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/create_session_metadata_table.sql"), collapse=" ")
create_Table <- dbGetQuery(con_Reef_database,query_create_table)

Metadata_sessions <- "https://docs.google.com/spreadsheets/d/1MLemH3IC8ezn5T1a1AYa5Wfa1s7h6Wz_ACpFY3NvyrM/edit?usp=sharing"
sessions <- as.data.frame(gsheet::gsheet2tbl(Metadata_sessions))
names(sessions)

session_metadata <- sessions_metadata_dataframe(sessions)
names(session_metadata)
head(session_metadata)

dbWriteTable(con_Reef_database, "metadata", session_metadata, row.names=TRUE, append=TRUE)
dbDisconnect(con_Reef_database)
~~~~


 
## Extract EXIF metadata from photos in a CSV FILES

~~~~
############################ WRITE EXIF METADATA CSV FILES ###################################################
wd <- "/media/julien/Julien_2To/data_deep_mapping/good_stuff"
sub_directories <- list.dirs(path=wd,full.names = TRUE,recursive = FALSE)
number_sub_directories <-length(sub_directories)

for (i in 1:number_sub_directories){
  extract_exif_metadata_in_csv(sub_directories[i])
}

############################ READ Exif metadata in CSV FILES ###################################################

template_df <- read.csv("/media/julien/Julien_2To/data_deep_mapping/done/session_2017_11_04_kite_Le_Morne/exif/All_Exif_metadata_template.csv",stringsAsFactors = FALSE)
timsetamp_DateTimeOriginal = as.POSIXct(unlist(template_df$DateTimeOriginal),"%Y:%m:%d %H:%M:%S", tz="Indian/Mauritius")
~~~~


## TRANSFORM TCF AND CSV FILES IN A DATAFRAME

~~~~
#############################################################################################################
current_wd<-getwd()
directory <- "/media/julien/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/gopro2"
dataframe_tcx_files <- return_dataframe_tcx_files(directory)
dataframe_csv_files <- return_dataframe_csv_exif_metadata_files(directory)
setwd(current_wd)
~~~~