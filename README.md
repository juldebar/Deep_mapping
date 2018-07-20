This is a repository providing R codes to manage underwater pictures and their spatial location

In this repository we use: 
 - [exifr](https://www.r-bloggers.com/extracting-exif-data-from-photos-using-r/) package to extract exif metadata from JPG images
 - [RPostgreSQL]() package to 
 - [trackeR]() package to 
 - [RPostgreSQL]() package to 
 - [RPostgreSQL]() package to 
 - 
 
 
 Data collected have to comply with the following file structure:
 
<img style="position: absolute; top: 0; right: 0; border: 0;" src="https://drive.google.com/uc?id=1xQYlJy1JxOig7gjsXCiPEg74Zgexq8_s" width="500">

Our goal is to use this data structure as an input for R codes which will parse the subdirectories and files to load information in a Postgres / Postgis database with the following conceptual model:
 
<img style="position: absolute; top: 0; right: 0; border: 0;" src="https://drive.google.com/uc?id=1KTMUd6SQ9UGR3xMrtDYsAB0vNSYUlUZ5" width="500">


The main steps of the workflow are :
 - `extract` general metadata (~ Dublin Core) from google spreadsheet and load them in a dedicated table of the database
 - extract metadata from photos with exifr package and load them them in a dedicated table of the database
 - **extract** data from GPS tracks (txc or gpx files) and load them them in a dedicated table of the database
 - correlation of GPS timestamps and photos timestamps to infer photos locations (done with a SQL query / trigger in Postgis)
 
 
 
The file [functions.R](https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R) contains the following functions:
 - [extract_exif_metadata_in_csv](https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R) 
 - [rename_exif_csv](https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R) 
 - [return_dataframe_tcx_files](https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R) 
 - [return_dataframe_csv_exif_metadata_files](https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R) 
 - [sessions_metadata_dataframe](https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R) 

## Set functions and connection details for Postgres / Postgis server (create your own "credentials_databases.R" file)

~~~~
###################################### LOAD SESSION METADATA ############################################################
source("https://raw.githubusercontent.com/juldebar/Deep_mapping/master/R/functions.R")
source("/home/julien/Bureau/CODES/credentials_databases.R")
# source("/home/julien/Bureau/CODES/Deep_mapping/R/credentials_postgres.R")
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


## TRANSFORM TCF AND CSV FILES IN A DATAFRAME

~~~~
current_wd<-getwd()
directory <- "/media/julien/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/gopro2"
dataframe_tcx_files <- return_dataframe_tcx_files(directory)
dataframe_csv_files <- return_dataframe_csv_exif_metadata_files(directory)
setwd(current_wd)
~~~~


## RENAME CSV files

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




# LOAD POSTGIS DATABASE WITH EXIF METADATA AND GPS TRACKS DATA 

##  Merge GPS tracks data and load them in the Postgres datbase
~~~~
###################################### LOAD GPS TRACKS DATA ############################################################
con_Reef_database <- dbConnect(DRV, user=User, password=Password, dbname=Dbname, host=Host)
query_create_table <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/create_tables_GPS_tracks.sql"), collapse=" ")
query_update_table_spatial_column <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/add_spatial_column.sql"), collapse=" ")
create_Table <- dbGetQuery(con_Reef_database,query_create_table)
# dbWriteTable(con_Reef_database, "gps_tracks", GPS_tracks_values, row.names=FALSE, append=TRUE)
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


##  3. Merge all exif metadata and load them in the Postgres / Pöstgis datbase


### 3.1 Extract EXIF metadata from each photo and store them in CSV FILES (one per session)

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

### 3.2 Merge all EXIF metadata (extracted before in CSV FILES) in a single data frame and load them in the Postgres / Pöstgis database


~~~~
###################################### LOAD PHOTOS EXIF CORE METADATA ############################################################

# All CSV files gathered in a single directory
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

### 3.3 Load all EXIF metadata (in  the  data frame) in the Postgres / Pöstgis database


~~~~
###################################### LOAD EXIF METADATA IN POSTGRES DATABASE ############################################################
con_Reef_database <- dbConnect(DRV, user=User, password=Password, dbname=Dbname, host=Host)
query_create_exif_core_metadata_table <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/create_exif_core_metadata_table.sql"), collapse=" ")
create__exif_core_metadata_table <- dbGetQuery(con_Reef_database,query_create_exif_core_metadata_table)
# dbWriteTable(con_Reef_database, "photos_exif_core_metadata", All_Core_Exif_metadata[1:10,], row.names=TRUE, append=TRUE)
dbWriteTable(con_Reef_database, "photos_exif_core_metadata", All_Core_Exif_metadata, row.names=TRUE, append=TRUE)
dbDisconnect(con_Reef_database)
~~~~
