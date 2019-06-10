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
working_directory <-  "/media/juldebar/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/Deep_Mapping/data_deep_mapping/gopro1/checked"
setwd(working_directory)

sub_directories <- list.dirs(path=working_directory,full.names = TRUE,recursive = FALSE)
# sub_directories <- list.dirs(path=working_directory,full.names = FALSE,recursive = FALSE)
number_sub_directories <-length(sub_directories)

metadata_pictures <- data.frame(session=character(), path=character(), file_name=character(), spatial_extent=character(), temporal_extent=character(), number_pictures=integer())

for (i in 1:number_sub_directories){
  this_directory <- sub_directories[i]
  setwd(this_directory)
  name_session <- gsub(paste0(dirname(this_directory),"/"),"",this_directory)
  tcx_file <- NULL
  temporal_extent <- NULL
  bounding_box <- NULL
  Number_of_Pictures <- NULL
  
  ############################################################
  ################### Number of Photos #######################
  ############################################################
  files <- NULL
  files <- list.files(path = paste(this_directory,"DCIM",sep="/"), pattern = "*.JPG",recursive = TRUE)
  if(length(files)>0){
    
    Number_of_Pictures <- length(files)
    ############################################################
    ################### TEMPORAL COVERAGE ######################
    ############################################################
    first_picture_metadata <- read_exif(paste(this_directory,"DCIM", files[1],sep="/"))
    start_date<- as.POSIXct(first_picture_metadata$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
    end_date<- as.POSIXct(read_exif(paste(this_directory,"DCIM",files[Number_of_Pictures],sep="/"))$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
    temporal_extent <- paste0("start=", start_date,";end=",end_date)
    ############################################################
    ################### Offset #######################
    ############################################################
    # reference_photo
    # reference_photo_timestamp <- as.POSIXct(reference_photo$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
    # timestamp_on_photo <- ""
    # Offset <- timestamp_on_photo - reference_photo_timestamp
    
  }else{
    Number_of_Pictures <- "No Photos"
    temporal_extent <- "No Photos"
  }
  ############################################################
  ################### SPATIAL COVERAGE #######################
  ############################################################
  tcx_file <- list.files(path=paste(this_directory,"GPS",sep="/"), pattern = "*.tcx",recursive = FALSE)
  if(length(tcx_file)>0){
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
  }else{
    tcx_file <- "No GPS file"
    bounding_box <- "No GPS file"
  }
  ############################################################
  ################### CREATE DATAFRAME #######################
  ############################################################
  newRow <- c(name_session,this_directory,tcx_file,bounding_box, temporal_extent, Number_of_Pictures)
  metadata_pictures <- rbind(metadata_pictures,newRow)
}
head(metadata_pictures)
setwd(working_directory)
write.csv(metadata_pictures, file = "metadata_sessions.csv")
sum(metadata_pictures$number_pictures)
