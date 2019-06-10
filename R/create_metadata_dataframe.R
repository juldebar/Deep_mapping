############################################################
################### Packages #######################
############################################################
library(trackeR)
library(dplyr)
library(exifr)
library(data.table)
codes_directory <-"/home/julien/Bureau/CODES/Deep_mapping/"

############################################################
################### Set directory #######################
############################################################
working_directory <-  "/media/julien/Deep_Mapping_4To/data_deep_mapping/2019/A"
setwd(working_directory)

sub_directories <- list.dirs(path=working_directory,full.names = TRUE,recursive = FALSE)
number_sub_directories <-length(sub_directories)

metadata_pictures <- data.frame(session_id=character(), path=character(), gps_file_name=character(), spatial_extent=character(), temporal_extent=character(), Number_of_Pictures=integer())

for (i in 1:number_sub_directories){
  this_directory <- sub_directories[i]
  setwd(this_directory)
  session_id <- gsub(paste0(dirname(this_directory),"/"),"",this_directory)
  gps_file <- NULL
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
  file_type<-"TCX" #  "GPX"  "TCX" "RTK"
  dataframe_gps_files <- return_dataframe_gps_files(this_directory,type=file_type)
  if(is.null(dataframe_gps_files)){
    file_type<-"GPX"
    dataframe_gps_files <- return_dataframe_gps_files(this_directory,type=file_type)
    }
  number_row<-nrow(dataframe_gps_files)
  if(number_row>0){
    for (t in 1:number_row){
      gps_file <- paste(dataframe_gps_files$path[t],dataframe_gps_files$file_name[t],sep="/")
      dataframe_gps_file <-NULL
      dataframe_gps_file <- return_dataframe_gps_file(wd=codes_directory, gps_file=gps_file, type=file_type, session_id=session_id)
#       name(dataframe_gps_file)
      xmin <- min(dataframe_gps_file$longitude)
      xmax <- max(dataframe_gps_file$longitude)
      ymin <- min(dataframe_gps_file$latitude)
      ymax <- max(dataframe_gps_file$latitude)
      bounding_box <- WKT <- paste("POLYGON((",xmin,ymin,",",xmin,ymax,",",xmax,ymax,",",xmax,ymin,",",xmin,ymin,"))",sep=" ")
    }
  }else{
    (cat("No GPS file when looking for TCX or GPX or RTK files"))
    gps_file <- "No GPS file"
    bounding_box <- "No GPS file"
    }
  
  ############################################################
  ################### CREATE DATAFRAME #######################
  ############################################################
  newRow <- data.frame(session_id=session_id,path=this_directory,gps_file_name=gps_file,spatial_extent=bounding_box, temporal_extent=temporal_extent, Number_of_Pictures=Number_of_Pictures)
  metadata_pictures <- rbind(metadata_pictures,newRow)
}


head(metadata_pictures)
setwd(working_directory)
write.csv(metadata_pictures,file = "metadata_sessions.csv",row.names = F)
nrow(metadata_pictures)
sum(metadata_pictures$Number_of_Pictures)


########################################################################################################################
################### Create a view for each session with the track of the survey as a polyline #######################
########################################################################################################################
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
