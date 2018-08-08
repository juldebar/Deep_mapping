############################################################
################### Packages #######################
############################################################
library(trackeR)
library(dplyr)
library(exifr)
library(data.table)

############################################################
################### Set directory #######################
############################################################
con_Reef_database <- dbConnect(DRV, user=User, password=Password, dbname=Dbname, host=Host)
template_query_create_view <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/create_view_session_template.sql"), collapse=" ")
query_metadata <- "SELECT * FROM metadata"
get_metadata  <- dbGetQuery(con_Reef_database,query_metadata)
number_row<-nrow(get_metadata)
for (i in 1:number_row) {
  query_create_view<- gsub("view_session_2018_03_31_kite_Le_Morne",get_metadata$related_view_name[i],template_query_create_view)
  query_create_view<- gsub("session_2018_03_31_kite_Le_Morne",get_metadata$identifier[i],template_query_create_view)
  create_view  <- dbGetQuery(con_Reef_database,query_create_view)
}



############################################################
################### Set directory #######################
############################################################
working_directory <-  "/media/julien/Julien_2To/data_deep_mapping/done"
setwd(working_directory)

sub_directories <- list.dirs(path=working_directory,full.names = TRUE,recursive = FALSE)
# sub_directories <- list.dirs(path=working_directory,full.names = FALSE,recursive = FALSE)
number_sub_directories <-length(sub_directories)
metadata_pictures <-NULL
metadata_pictures <- data.frame(session=character(), path=character(), file_name=character(), spatial_extent=character(), temporal_extent=character(), number_pictures=integer())

for (i in 1:number_sub_directories){
  this_directory <- sub_directories[i]
  setwd(this_directory)
  name_session <- gsub(dirname(this_directory),"",this_directory)
  name_session <- gsub("/","",parent_directory)
  
  ############################################################
  ################### Number of Photos #######################
  ############################################################
  files <- list.files(path = paste(this_directory,"DCIM",sep="/"), pattern = "*.JPG",recursive = TRUE)
  Number_of_Pictures <- length(files)
  ############################################################
  ################### SPATIAL COVERAGE #######################
  ############################################################
  tcx_file <- list.files(path=paste(this_directory,"GPS",sep="/"), pattern = "*.tcx",recursive = FALSE)
  runDF <- NULL
  #   # runDF <- readTCX(file=file, timezone = "GMT")
  runDF <- readTCX(file=paste(this_directory,"GPS",tcx_file,sep="/"))
  select_columns = subset(runDF, select = c(latitude,longitude,altitude,time,heart.rate))
  GPS_tracks_values <- NULL
  GPS_tracks_values = rename(select_columns, latitude=latitude,longitude=longitude, altitude=altitude, heart_rate=heart.rate, time=time)
  names(GPS_tracks_values)
  xmin <- min(GPS_tracks_values$longitude)
  xmax <- max(GPS_tracks_values$longitude)
  ymin <- min(GPS_tracks_values$latitude)
  ymax <- max(GPS_tracks_values$latitude)
  bounding_box <- WKT <- paste("POLYGON((",xmin,ymin,",",xmin,ymax,",",xmax,ymax,",",xmax,ymin,",",xmin,ymin,"))",sep=" ")
  ############################################################
  ################### TEMPORAL COVERAGE ######################
  ############################################################
  first_picture_metadata <- read_exif(paste(this_directory,"DCIM", files[1],sep="/"))
  start_date<- as.POSIXct(first_picture_metadata$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
  end_date<- as.POSIXct(read_exif(paste(this_directory,"DCIM",files[Number_of_Pictures],sep="/"))$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
  temporal_extent <- paste("start=", start_date,";end=",end_date,sep="")
  
  ############################################################
  ################### Offset #######################
  ############################################################
  # reference_photo
  # reference_photo_timestamp <- as.POSIXct(reference_photo$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
  # timestamp_on_photo <- ""
  # Offset <- timestamp_on_photo - reference_photo_timestamp
  ############################################################
  ################### CREATE DATAFRAME #######################
  ############################################################
  
  newRow <- data.frame(session=name_session,path=this_directory,file_name=tcx_file,spatial_extent=bounding_box, temporal_extent=temporal_extent, number_pictures=Number_of_Pictures)
  metadata_pictures <- rbind(metadata_pictures,newRow)
}
setwd(working_directory)

metadata_pictures
write.csv(metadata_pictures, file = "metadata_sessions.csv")
sum(metadata_pictures$number_pictures)





