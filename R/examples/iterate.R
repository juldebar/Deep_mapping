
# list all repositories from a path or from gsheet (offset is in the gsheet)

images_directory <- "/media/juldebar/Deep_Mapping_one1/data_deep_mapping/2019/to_do/session_2019_01_26_kite_Le_Morne_Ambulante_Nord"
photo_time <- "2019-01-26 09:28:54"
GPS_time <- "2019-01-26 09:18:00"

images_directory <- "/media/juldebar/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/Deep_Mapping/data_deep_mapping/gopro1/checked/session_2017_12_09_kite_Bel_Ombre"
photo_time <- "2015-02-05 13:52:53"
GPS_time <- "2017-12-09 11:31:00"
photo_path="/media/juldebar/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/Deep_Mapping/data_deep_mapping/gopro1/checked/session_2017_12_09_kite_Bel_Ombre/DCIM/142GOPRO/G0032066.JPG"
# file:///media/juldebar/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/Deep_Mapping/data_deep_mapping/gopro1/checked/session_2017_12_09_kite_Bel_Ombre/DCIM/142GOPRO/G0032066.JPG
etl_workflow(images_directory,photo_path,photo_time,GPS_time, mime_type = "*.JPG", time_zone="Indian/Mauritius")

etl_workflow <- function(images_directory,photo_path,photo_time,GPS_time, mime_type = "*.JPG", time_zone="Indian/Mauritius"){
  
  rm(list=ls())
  
  codes_directory <-"/home/julien/Bureau/CODES/Deep_mapping/"
  setwd(codes_directory)
  source(paste0(codes_directory,"R/functions.R"))
  source(paste0(codes_directory,"R/credentials_databases.R"))
  con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)
  
  session_id <- gsub(paste0(dirname(images_directory),"/"),"",images_directory)
  offset <-difftime(photo_time, GPS_time, units="secs")
  ########################################################################################################################################################################################
  ###################### EXTRACT exif metadata elements & store them in a CSV file & LOAD THEM INTO POSTGRES DATABASE  #########
  ########################################################################################################################################################################################
  # extract exif metadata and store it into a CSV or RDS file
  template_df <- read.csv(paste0(codes_directory,"CSV/All_Exif_metadata_template.csv"),stringsAsFactors = FALSE)
  last_metadata_pictures <- extract_exif_metadata_in_csv(images_directory=images_directory, template_df, load_metadata_in_database=FALSE,time_zone="Indian/Mauritius")
  attr(last_metadata_pictures$GPSDateTime,"tzone")
  attr(last_metadata_pictures$DateTimeOriginal,"tzone")
  
  # read the exif metadata from RDS file
  exif_core_metadata_elements <- list.files(path = paste0(images_directory,"/METADATA/exif"), pattern = "Core_Exif_metadata_")
  photos_metadata <-NULL
  for (f in exif_core_metadata_elements){
    if(grepl(".RDS",f)){photos_metadata <- readRDS(paste0(images_directory,"/METADATA/exif/",f))}
  }
  
  # load the exif metadata in the SQL database
  load_exif_metadata_in_database(con_Reef_database, codes_directory, photos_metadata, create_table=TRUE)
  
  #  Check that the SQL database was properly loaded
  check_database <- dbGetQuery(con_Reef_database, paste0("SELECT * FROM photos_exif_core_metadata WHERE session_id='",session_id,"' LIMIT 10"))
  check_database
  ############################################################################################
  ###################### EXTRACT GPS TRACKS DATA AND LOAD THEM INTO POSTGRES DATABASE ########
  ############################################################################################ 
  # define expected mime type for the search
  file_type<-"TCX" #  "GPX"  "TCX" "RTK"
  
  # check the number of GPS files for the session (sometimes more than one: battery issue..)
  # Use "dataframe_gps_files" to list all gps files
  dataframe_gps_files <- return_dataframe_gps_files(images_directory,type=file_type)
  number_row<-nrow(dataframe_gps_files)
  
  # if more than one (sometimes for some reasons, the same session has multiple GPS tracks) => iterate => difference between end point and start point > frequency
  if(number_row>0){
    for (t in 1:number_row){
      gps_file <- paste(dataframe_gps_files$path[t],dataframe_gps_files$file_name[t],sep="/")
      
      # Use "dataframe_gps_file" to turn the gps file into a data frame
      dataframe_gps_file <-NULL
      dataframe_gps_file <- return_dataframe_gps_file(wd=codes_directory, gps_file=gps_file, type=file_type, session_id=session_id)
      duplicates <- distinct(dataframe_gps_file, time)
      duplicates_number <- nrow(dataframe_gps_file)-nrow(duplicates)
      paste0("the file has :", duplicates_number," duplicates")
      load_gps_tracks_in_database(con_Reef_database, codes_directory, dataframe_gps_file, create_table=FALSE)
      # generate a thumbnail of the map
      # plot_tcx(gps_file,images_directory)
    }
  }else(cat("No GPS file when looking for TCX or GOX or RTK files"))
  ############################################################################################
  ###################### INFER LOCATION OF PHOTOS FROM GPS TRACKS TIMESTAMP  ########
  ############################################################################################ 
  infer_photo_location_from_gps_tracks(con_Reef_database, images_directory, codes_directory,session_id , offset=offset,create_view=TRUE)
  nrow(photos_metadata)
  nrow(dataframe_gps_file)
  nrow(dataframe_gps_file)
  dbDisconnect(con_Reef_database)
  
}

Session_metadata_table <- "https://docs.google.com/spreadsheets/d/1MLemH3IC8ezn5T1a1AYa5Wfa1s7h6Wz_ACpFY3NvyrM/edit?usp=sharing"
Datasets <- as.data.frame(gsheet::gsheet2tbl(Session_metadata_table))
session_metadata <-filter(Datasets, Identifier==session_id)
photo_time_gsheet <- session_metadata$Photo_time
GPS_time <- session_metadata$GPS_time

# for each row => 

