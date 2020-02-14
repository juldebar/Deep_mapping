# Main goal

This is a repository providing R codes to manage exif metadata of photos and infer their spatial location from GPS tracks (from other devices: smartphone, watch..). The repository provides R codes to extract exif metadata and store them in a Postgres / Postgis database along with spatial data (from GPS tracker).

The project has been presented at FOSS4G 2018 conference held in Dar Es Salaam: see [Slides](https://docs.google.com/presentation/d/1MdYl-AsnHPwe-fCCfOb4c2fpHSmGKWIaz5mPehIHt_o).

# R packages


In this repository we use: 
 - [exifr](https://www.r-bloggers.com/extracting-exif-data-from-photos-using-r/) package to extract exif metadata from JPG images
 - [RPostgreSQL]() package to 
 - [trackeR]() package to 
 - [dplyr]() package to 
 - [data.table]() package to 
 - [geometa]() package to 
 - [geonapi]() package to 
 - [geosapi]() package to 
 

# File structure

Data collected have to comply with the following file structure:
 
<img style="position: absolute; top: 0; right: 0; border: 0;" src="https://drive.google.com/uc?id=1xQYlJy1JxOig7gjsXCiPEg74Zgexq8_s" width="800">

# Database model (implemented in Postgres / Postgis)

Our goal is to use this data structure as an input for R codes which will parse the subdirectories and files to load information in a Postgres / Postgis database with the following conceptual model (UML schema):
 
<!-- <img style="position: absolute; top: 0; right: 0; border: 0;" src="https://raw.githubusercontent.com/juldebar/Deep_mapping/master/SQL/Reef_Database.svg" width="800"> -->
<img src="https://raw.github.com/juldebar/Deep_mapping/master/SQL/Reef_Database.svg">



## Main steps of the workflow


The main steps of the workflow are :
 - `extract` general metadata (~ Dublin Core) from google spreadsheet and load them in a dedicated table of the database
 - extract metadata from photos with exifr package and load them them in a dedicated table of the database
 - **extract** data from GPS tracks (txc or gpx files) and load them them in a dedicated table of the database
 - correlation of GPS timestamps and photos timestamps to infer photos locations (done with a SQL query / trigger in Postgis)
 
## Main functions (R)
 
The file [functions.R](https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R) contains the following functions:
 - [sessions_metadata_dataframe](https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R) : this script load the metadata describing all sessions in a data frame (from a google spreadsheet) and load them in the "metadata" table of the Postgres / Postgis database.
 - [return_dataframe_tcx_files](https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R): this script will find all TXC files and merge them into a single data frame (which keep tracks of relation sessions). This will be used to load GPS tracks data in the "gps_tracks" of the Postgres / Postgis database.
 - [extract_exif_metadata_in_csv](https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R) : for a session, this script will copy exif metadata stored in the picture into a single CSV file,
 - [return_dataframe_csv_exif_metadata_files](https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R): this script will find all CSV files storing exif metadata of each session and merge them into a single data frame (which keep tracks of relation sessions). This will be used to load Exif metadata in the "photos_exif_core_metadata" table of Postgres / Postgis database.
 - [rename_exif_csv](https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R), if needed CSV files can be renamed

## Set functions and connection details for Postgres / Postgis server (create your own "credentials_databases.R" file)

~~~~
###################################### LOAD SESSION METADATA ############################################################

source("https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R")
codes_directory <-"~/Bureau/CODES/Deep_mapping/"
setwd(codes_directory)
source(paste0(codes_directory,"R/functions.R"))
con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)
source(paste0(codes_directory,"R/credentials_databases.R"))
Session_metadata_table <- "https://docs.google.com/spreadsheets/d/1MLemH3IC8ezn5T1a1AYa5Wfa1s7h6Wz_ACpFY3NvyrM/edit?usp=sharing"
Datasets <- as.data.frame(gsheet::gsheet2tbl(Session_metadata_table))
Datasets %>% filter(Checked=='YES')
  
images_directory <- "/media/julien/39160875-fe18-4080-aab7-c3c3150a630d/julien/go_pro_all/session_2018_01_01_kite_Le_Morne"
session_id <- gsub(paste0(dirname(images_directory),"/"),"",images_directory)

session_metadata <-filter(Datasets, Identifier==session_id)
session_metadata$Photo_for_GPS_Time_Correlation
photo_time <- as.POSIXct(session_metadata$Photo_time, tz="Indian/Mauritius")
GPS_time <- as.POSIXct(session_metadata$GPS_time, tz="UTC")
offset <-difftime(photo_time, GPS_time, units="secs")
offset
~~~~
 
## Create "metadata" table (to describe sessions) in the Postgres/ Postgis database and fill it with metadata stored in a google spreadsheet

~~~~
###################################### LOAD SESSION METADATA ############################################################
con_Reef_database <- dbConnect(DRV, user=User, password=Password, dbname=Dbname, host=Host)
sql_query_create_table <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/create_session_metadata_table.sql"), collapse=" ")
create_Table <- dbGetQuery(con_Reef_database,sql_query_create_table)

Metadata_sessions <- "https://docs.google.com/spreadsheets/d/1MLemH3IC8ezn5T1a1AYa5Wfa1s7h6Wz_ACpFY3NvyrM/edit?usp=sharing"
sessions <- as.data.frame(gsheet::gsheet2tbl(Metadata_sessions))
names(sessions)
session_metadata <- sessions_metadata_dataframe(sessions)
head(session_metadata)

load_metadata_table <- WriteTable(con_Reef_database, "metadata", session_metadata, row.names=TRUE, append=TRUE)
sql_query_update_metadata_table <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/update_spatial_column_table_metadata.sql"), collapse=" ")
metadata_table_updated <- dbGetQuery(con_Reef_database,sql_query_update_metadata_table)

dbDisconnect(con_Reef_database)
~~~~

## TRANSFORM TCF AND CSV FILES IN A DATAFRAME


##  2. Merge GPS tracks data and load them in the Postgres / Postgis database


~~~~
current_wd<-getwd()
directory <- "/media/julien/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/gopro2"
dataframe_tcx_files <- return_dataframe_tcx_files(directory)
dataframe_csv_files <- return_dataframe_csv_exif_metadata_files(directory)
setwd(current_wd)
~~~~


~~~~
###################################### CREATE GPS TRACKS TABLE ############################################################
query_create_table <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/create_tables_GPS_tracks.sql"), collapse=" ")
create_Table <- dbGetQuery(con_Reef_database,query_create_table)
###################################### LOAD GPS TRACKS FOR A SINGLE SESSION ############################################################
#---------------------------------------------------------------------------------------------------------------------------
dataframe_tcx_files <- return_dataframe_tcx_files(images_directory)
tcx_file <- paste(dataframe_tcx_files$path,dataframe_tcx_files$file_name,sep="/")
type<-"TCX"
dataframe_gps_file <-return_dataframe_gps_file(codes_directory, tcx_file, type, session_id,load_in_database=FALSE)
head(dataframe_gps_file)
load_gps_tracks_in_database(con_Reef_database, codes_directory, dataframe_gps_file, create_table=FALSE)
#---------------------------------------------------------------------------------------------------------------------------
###################################### LOAD ALL GPS TRACKS AT ONCE ############################################################
wd <- "/media/julien/Julien_2To/data_deep_mapping/good_stuff"
dataframe_tcx_files <- return_dataframe_tcx_files(wd)

number_row<-nrow(dataframe_tcx_files)
for (t in 1:number_row){
  row <- dataframe_tcx_files[t,]
  session <- dataframe_tcx_files$session[t]
  path <- dataframe_tcx_files$path[t]
  file_name <- dataframe_tcx_files$file_name[t]
  file = paste(path,file_name,sep="/")
  runDF <- NULL
  #   # runDF <- readTCX(file=file, timezone = "GMT")
  runDF <- readTCX(file=file)
  runDF$session <- session
  select_columns = subset(runDF, select = c(session,latitude,longitude,altitude,time,heart.rate))
  GPS_tracks_values = rename(select_columns, session_id=session, latitude=latitude,longitude=longitude, altitude=altitude, heart_rate=heart.rate, time=time)
  names(GPS_tracks_values)
  # GPS_tracks_values$fid <-c(1:nrow(GPS_tracks_values))
  # GPS_tracks_values <- GPS_tracks_values[,c(6,1,2,3,4,5)]
  # GPS_tracks_values$time <- as.POSIXct(GPS_tracks_values$time, "%Y-%m-%d %H:%M:%OS")
  GPS_tracks_values$the_geom <- NA
  dbWriteTable(con_Reef_database, "gps_tracks", GPS_tracks_values, row.names=FALSE, append=TRUE)
}

update_Table <- dbGetQuery(con_Reef_database,query_update_table_spatial_column)
~~~~


##  3. Merge all exif metadata and load them in the Postgres / Postgis database


### 3.1 Extract EXIF metadata from each photo and store them in CSV FILES (one per session)

Extract exif metadata from photos and store them in CSV files



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

############################ READ Exif metadata in CSV FILES ###################################################

template_df <- read.csv(paste0(codes_directory,"CSV/All_Exif_metadata_template.csv"),stringsAsFactors = FALSE)
last_metadata_pictures <- extract_exif_metadata_in_csv(images_directory=images_directory, template_df, load_metadata_in_database=FALSE)
exif_core_metadata_elements <- list.files(path = paste0(images_directory,"/METADATA/exif"), pattern = "Core_Exif_metadata_")
photos_metadata <- readRDS(exif_core_metadata_elements)
load_exif_metadata_in_database(con_Reef_database, codes_directory, photos_metadata, create_table=FALSE)
~~~~

### 3.2 Merge all EXIF metadata (extracted before in CSV FILES) in a single data frame and load them in the Postgres / Postgis database

Find all CSV files and return the list in a dataframe

~~~~
current_wd<-getwd()
directory <- "/media/julien/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/gopro2"
dataframe_csv_files <- return_dataframe_csv_exif_metadata_files(directory)
setwd(current_wd)
~~~~

Copy all CSV files in a single directory (TO BE DONE)

Merge all CSV files gathered in a single directory
~~~~
###################################### LOAD PHOTOS EXIF CORE METADATA FROM ALL SESSSIONS ############################################################
setwd("/tmp/csv")
filenames <- list.files(full.names=TRUE)
All <- lapply(filenames,function(i){
  read.csv(i, header=TRUE, skip=0)
})
All_Core_Exif_metadata <- do.call(rbind.data.frame, All)
head(All_Core_Exif_metadata)
sapply(All_Core_Exif_metadata, class)
All_Core_Exif_metadata$gpsdatetim = as.character(unlist(All_Core_Exif_metadata$gpsdatetim))
All_Core_Exif_metadata$datetimeor = as.character(All_Core_Exif_metadata$datetimeor)
All_Core_Exif_metadata$geometry_postgis <- NA
All_Core_Exif_metadata$geometry_postgis = as.numeric(unlist(All_Core_Exif_metadata$geometry_postgis))
All_Core_Exif_metadata$geometry_gps_correlate <- NA
All_Core_Exif_metadata$geometry_gps_correlate = as.numeric(unlist(All_Core_Exif_metadata$geometry_gps_correlate))
All_Core_Exif_metadata$geometry_native <- NA
All_Core_Exif_metadata$geometry_native = as.numeric(unlist(All_Core_Exif_metadata$geometry_native))
# All_Core_Exif_metadata %>% top_n(2)
head(All_Core_Exif_metadata)
write.csv(All_Core_Exif_metadata,"All_Core_Exif_metadata.csv", row.names=FALSE)
~~~~

OR 

~~~~
###################################### LOAD PHOTOS EXIF CORE METADATA ############################################################

current_wd<-getwd()
directory <- "/media/julien/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/gopro2"
dataframe_csv_files <- return_dataframe_csv_exif_metadata_files(directory)
setwd(current_wd)


number_row<-nrow(dataframe_csv_files)
for (csv in 1:number_row){
  row <- dataframe_csv_files[csv,]
  session <- dataframe_csv_files$session[csv]
  path <- dataframe_csv_files$path[csv]
  file_name <- dataframe_csv_files$file_name[csv]
  if(file_name=="All_Exif_metadata.csv"){
    cat("\n GOTCHA \n")
    file = paste(path,file_name,sep="/")
    relative_path <- gsub(directory,"",dirname(as.character(path)))
    CSV_total <- NULL
    csv_data_frame <- NULL
    CSV_total <- read.csv(file=file)
    CSV_total <- read.csv(file=file, stringsAsFactors = FALSE)
    # CSV_total <- read.csv(file="/media/julien/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/gopro2/session_2018_03_31_kite_Le_Morne/DCIM/exif/All_Exif_metadata.csv", stringsAsFactors = FALSE)
    
    metadata_pictures <- select(CSV_total,
                                FileName,
                                GPSLatitude,
                                GPSLongitude,
                                GPSDateTime,
                                DateTimeOriginal,
                                LightValue,
                                ImageSize,
                                Model)
    sapply(metadata_pictures, class)
    metadata_pictures$session <- session
    metadata_pictures$session_photo_number <-c(1:nrow(metadata_pictures))
    metadata_pictures$relative_path <- relative_path
    metadata_pictures$session = as.character(unlist(metadata_pictures$session))
    metadata_pictures$GPSLatitude = as.numeric(unlist(metadata_pictures$GPSLatitude))
    metadata_pictures$GPSLongitude = as.numeric(unlist(metadata_pictures$GPSLongitude))
    # metadata_pictures$GPSDateTime = as.POSIXct(unlist(metadata_pictures$GPSDateTime),"%Y-%m-%d %H:%M:%S", tz="UTC")
    # metadata_pictures$DateTimeOriginal = as.POSIXct(metadata_pictures$DateTimeOriginal, format="%Y-%m-%d %H:%M:%S", tz="UTC")
    metadata_pictures$GPSDateTime = as.character(unlist(metadata_pictures$GPSDateTime))
    metadata_pictures$DateTimeOriginal = as.character(metadata_pictures$DateTimeOriginal)
    metadata_pictures$geometry_postgis <- NA
    metadata_pictures$geometry_postgis = as.numeric(unlist(metadata_pictures$geometry_postgis))
    metadata_pictures$geometry_gps_correlate <- NA
    metadata_pictures$geometry_gps_correlate = as.numeric(unlist(metadata_pictures$geometry_gps_correlate))
    metadata_pictures$geometry_native <- NA
    metadata_pictures$geometry_native = as.numeric(unlist(metadata_pictures$geometry_native))
    csv_data_frame = rename(metadata_pictures, session_id=session, session_photo_number=session_photo_number, relative_path=relative_path, filename=FileName, gpslatitud=GPSLatitude, gpslongitu=GPSLongitude, gpsdatetim=GPSDateTime, datetimeor=DateTimeOriginal, lightvalue=LightValue, imagesize=ImageSize, model=Model)
    csv_data_frame <- csv_data_frame[,c(9,10,11,1,2,3,4,5,6,7,8,12,13,14)]
    names(csv_data_frame)
    head(csv_data_frame)
    sapply(csv_data_frame, class)
    ###################################### LOAD PHOTOS EXIF CORE METADATA ############################################################
    setwd(as.character(path))
    write.csv(csv_data_frame, "Core_Exif_metadata_new.csv",row.names = F)
    # dbWriteTable(con_Reef_database, "photos_exif_core_metadata", csv_data_frame, row.names=FALSE, append=TRUE)
  }
}
~~~~

### 3.3 Load all EXIF metadata (in  the  data frame) in the Postgres / Postgis database


~~~~
###################################### LOAD EXIF METADATA IN POSTGRES DATABASE ############################################################
con_Reef_database <- dbConnect(DRV, user=User, password=Password, dbname=Dbname, host=Host)
query_create_exif_core_metadata_table <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/create_exif_core_metadata_table.sql"), collapse=" ")
create__exif_core_metadata_table <- dbGetQuery(con_Reef_database,query_create_exif_core_metadata_table)
# dbWriteTable(con_Reef_database, "photos_exif_core_metadata", All_Core_Exif_metadata[1:10,], row.names=TRUE, append=TRUE)
dbWriteTable(con_Reef_database, "photos_exif_core_metadata", All_Core_Exif_metadata, row.names=TRUE, append=TRUE)
dbDisconnect(con_Reef_database)
~~~~


#### RENAME CSV files

~~~~
# wd <- "/media/julien/Julien_2To/data_deep_mapping/done"
wd <- "/media/usb0/data_deep_mapping/done"
sub_directories <- list.dirs(path=wd,full.names = TRUE,recursive = FALSE)
number_sub_directories <-length(sub_directories)

for (i in 1:number_sub_directories){
  rename_exif_csv(sub_directories[i])
}

# images_directory <- "/media/usb0/data_deep_mapping/done/session_2018_06_02_kite_Le_Morne"
~~~~


<!---
Parameters Name | Type |  Data Type | Default value |  Controlled values | Definition
--------|--------|--------|--------|--------|--------
runNumb | Input | Integer | 7 | - | Select the run to run
filenameVpa | Input | String | bfte2014 | - | Define file names for the vpa
seedNumb | Input | Integer | -911 | - | Select the seed number to use for the run
XXX | ... | ... | ... | ... | ...
-->


