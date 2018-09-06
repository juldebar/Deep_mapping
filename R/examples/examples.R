rm(list=ls())
############################################################################################
######################SET DIRECTORIES & LOAD SOURCES & CONNECT DATABASE##################################
############################################################################################
images_directory <- "/media/julien/3465-3131/session_2018_08_25_Zanzibar_Snorkelling"
codes_directory <-"~/Bureau/CODES/Deep_mapping/"
# codes_directory <-"~/Deep_mapping-master/"
setwd(codes_directory)
source(paste0(codes_directory,"R/functions.R"))
source(paste0(codes_directory,"R/credentials_databases.R"))
con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)
session_id <- gsub(paste0(dirname(images_directory),"/"),"",images_directory)

Session_metadata_table <- "https://docs.google.com/spreadsheets/d/1MLemH3IC8ezn5T1a1AYa5Wfa1s7h6Wz_ACpFY3NvyrM/edit?usp=sharing"
Datasets <- as.data.frame(gsheet::gsheet2tbl(Session_metadata_table))
session_metadata <-filter(Datasets, Identifier==session_id)
photo_time <- as.POSIXct(session_metadata$Photo_time, format="%Y-%m-%d %H:%M:%S", tz="UTC")
GPS_time <- as.POSIXct(session_metadata$GPS_time, tz="UTC")
attr(photo_time,"tzone")
offset_gsheet <-difftime(photo_time, GPS_time, units="secs")
offset_gsheet
############################################################################################
###################### EXTRACT CSV METADATA ##################################
############################################################################################
template_df <- read.csv(paste0(codes_directory,"CSV/All_Exif_metadata_template.csv"),stringsAsFactors = FALSE)
last_metadata_pictures <- extract_exif_metadata_in_csv(images_directory=images_directory, template_df, load_metadata_in_database=FALSE,time_zone="UTC")
attr(last_metadata_pictures$DateTimeOriginal,"tzone")

exif_core_metadata_elements <- list.files(path = paste0(images_directory,"/METADATA/exif"), pattern = "Core_Exif_metadata_")
photos_metadata <-NULL
photos_metadata <- readRDS(paste0(images_directory,"/METADATA/exif/",exif_core_metadata_elements))
attr(photos_metadata$DateTimeOriginal,"tzone")

load_exif_metadata_in_database(con_Reef_database, codes_directory, photos_metadata, create_table=FALSE)

check_database <- dbGetQuery(con_Reef_database, paste0("SELECT * FROM photos_exif_core_metadata WHERE session_id='",session_id,"' LIMIT 10"))
check_database
############################################################################################
###################### EXTRACT GPS TRACKS DATA AND LOAD THEM INTO POSTGRES DATABASE ########
############################################################################################ 
set_time_zone <- dbGetQuery(con_Reef_database, "SET timezone = 'UTC'")
# check the number of GPS files for the session (sometimes more than one: battery issue..)
file_type<-"GPX"
file_type<-"TCX"
#file_type<-"TCX" file_type<-"GPX" file_type<-"RTK"
dataframe_gps_files <- return_dataframe_gps_files(images_directory,type=file_type)
number_row<-nrow(dataframe_gps_files)
number_row
# if only one GPS file
if(number_row==1){
gps_file <- paste(dataframe_gps_files$path,dataframe_gps_files$file_name,sep="/")
dataframe_gps_file <-NULL
dataframe_gps_file <- return_dataframe_gps_file(codes_directory, gps_file, type=file_type, session_id,load_in_database=FALSE)
head(dataframe_gps_file)
nrow(dataframe_gps_file)
attr(dataframe_gps_file$time,"tzone")
duplicates <- distinct(dataframe_gps_file, time)
duplicates_number <- nrow(dataframe_gps_file)-nrow(duplicates)
paste0("the file has :", duplicates_number," duplicates")
load_gps_tracks_in_database(con_Reef_database, codes_directory, dataframe_gps_file, create_table=FALSE)
# generate a thumbnail of the map
# plot_tcx(tcx_file,images_directory)
}
# if more than one => iterate => difference between end point and start point > frequency
if(number_row>1){
  for (t in 1:number_row){
    row <- dataframe_gps_files[t,]
    path <- dataframe_gps_files$path[t]
    file_name <- dataframe_gps_files$file_name[t]
    gps_file = paste(path,file_name,sep="/")
    dataframe_gps_file <-return_dataframe_gps_file(codes_directory, gps_file, type=file_type, session_id,load_in_database=FALSE)
    attr(dataframe_gps_file$time,"tzone")
    duplicates <- distinct(dataframe_gps_file, time)
    duplicates_number <- nrow(dataframe_gps_file)-nrow(duplicates)
    paste0("the file has :", duplicates_number," duplicates")
    load_gps_tracks_in_database(con_Reef_database, codes_directory, dataframe_gps_file, create_table=FALSE)
  }
}
############################################################################################
###################### INFER LOCATION OF PHOTOS FROM GPS TRACKS TIMESTAMP  ########
############################################################################################ 
offset <- return_offset(con_Reef_database, session_metadata)
offset
infer_photo_location_from_gps_tracks(con_Reef_database, images_directory, codes_directory,session_id , offset)
############################################################################################
###################### CLOSE  ########
############################################################################################ 
dbDisconnect(con_Reef_database)
