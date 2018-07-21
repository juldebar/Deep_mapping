template_df <- read.csv("/home/julien/Bureau/CODES/Deep_mapping/CSV/All_Exif_metadata_template.csv",stringsAsFactors = FALSE)
# sapply(template_df,class)
# head(template_df)
images_directory <-"/media/julien/3564-3063/session_2018_07_14_Le_Morne_Manawa"
source("/home/julien/Bureau/CODES/Deep_mapping/R/functions.R")
last_metadata_pictures <- extract_exif_metadata_in_csv(images_directory=images_directory)

head(last_metadata_pictures)
sapply(last_metadata_pictures,class)
class(last_metadata_pictures$LightValue)
last_metadata_pictures$DateTimeOriginal
last_metadata_pictures$GPSDateTime

# SUR CSV ALL METADATA
# CSV_total$ThumbnailImage[1] 
# CSV_total$ThumbnailOffset[1]
# CSV_total$ThumbnailLength[1]

# toto <- readRDS("/media/julien/3564-3063/session_2018_07_14_Le_Morne_Manawa/METADATA/exif/All_Exif_metadata_session_2018_07_14_Le_Morne_Manawa.RDS")
toto <- readRDS("/media/julien/3564-3063/session_2018_07_14_Le_Morne_Manawa/METADATA/exif/Core_Exif_metadata_session_2018_07_14_Le_Morne_Manawa.RDS")
sapply(toto,class)
head(toto)
toto$GPSDateTime


con_Reef_database <- dbConnect(DRV, user=User, password=Password, dbname=Dbname, host=Host)
query_create_exif_core_metadata_table <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/create_exif_core_metadata_table.sql"), collapse=" ")
create__exif_core_metadata_table <- dbGetQuery(con_Reef_database,query_create_exif_core_metadata_table)
# dbWriteTable(con_Reef_database, "photos_exif_core_metadata", All_Core_Exif_metadata[1:10,], row.names=TRUE, append=TRUE)
dbWriteTable(con_Reef_database, "photos_exif_core_metadata", toto, row.names=FALSE, append=TRUE)
dbDisconnect(con_Reef_database)

#################################################################################################vv 
dataframe_tcx_files <- return_dataframe_tcx_files(images_directory)


con_Reef_database <- dbConnect(DRV, user=User, password=Password, dbname=Dbname, host=Host)
query_create_table <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/create_tables_GPS_tracks.sql"), collapse=" ")
query_update_table_spatial_column <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/add_spatial_column.sql"), collapse=" ")
create_Table <- dbGetQuery(con_Reef_database,query_create_table)
# dbWriteTable(con_Reef_database, "gps_tracks", GPS_tracks_values, row.names=FALSE, append=TRUE)

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
  # head(runDF)
  runDF$session <- session
  runDF$time <- as.POSIXct(runDF$time, "%Y:%m:%d %H:%M:%S", tz="UTC")
  
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
