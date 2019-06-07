rm(list=ls())
############################################################################################
######################SET DIRECTORIES & LOAD SOURCES & CONNECT DATABASE##################################
############################################################################################
images_directory <- "/media/juldebar/Deep_Mapping_one/data_deep_mapping/test/session_2019_05_21_snorkelling_Prairie"
# images_directory <- "/home/julien/Documents/all_sessions"
codes_directory <-"/home/julien/Bureau/CODES/Deep_mapping/"
# codes_directory <-"~/Deep_mapping-master/"
setwd(codes_directory)
source(paste0(codes_directory,"R/functions.R"))
source(paste0(codes_directory,"R/credentials_databases.R"))
con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)
session_id <- gsub(paste0(dirname(images_directory),"/"),"",images_directory)

Session_metadata_table <- "https://docs.google.com/spreadsheets/d/1MLemH3IC8ezn5T1a1AYa5Wfa1s7h6Wz_ACpFY3NvyrM/edit?usp=sharing"
Datasets <- as.data.frame(gsheet::gsheet2tbl(Session_metadata_table))
session_metadata <-filter(Datasets, Identifier==session_id)
# photo_time <- as.POSIXct(session_metadata$Photo_time, format="%Y-%m-%d %H:%M:%S", tz="UTC")
photo_time <- as.POSIXct(session_metadata$Photo_time, format="%Y-%m-%d %H:%M:%S",tz="UTC+04:00")

GPS_time <- as.POSIXct(session_metadata$GPS_time, tz="UTC")
attr(photo_time,"tzone")
offset_gsheet <-difftime(photo_time, GPS_time, units="secs")
offset_gsheet
########################################################################################################################################################################################
###################### EXTRACT exif metadata elements & store them in a CSV file & LOAD THEM INTO POSTGRES DATABASE  #########
########################################################################################################################################################################################
# extract exif metadata and store it into a CSV or RDS file
template_df <- read.csv(paste0(codes_directory,"CSV/All_Exif_metadata_template.csv"),stringsAsFactors = FALSE)
# last_metadata_pictures <- extract_exif_metadata_in_csv(images_directory=images_directory, template_df, load_metadata_in_database=FALSE,time_zone="UTC+04:00")
last_metadata_pictures <- extract_exif_metadata_in_csv(images_directory=images_directory, template_df, load_metadata_in_database=FALSE,time_zone="Indian/Mauritius")
attr(last_metadata_pictures$GPSDateTime,"tzone")
attr(last_metadata_pictures$DateTimeOriginal,"tzone")

# read the exif metadata
exif_core_metadata_elements <- list.files(path = paste0(images_directory,"/METADATA/exif"), pattern = "Core_Exif_metadata_")
photos_metadata <-NULL
for (f in exif_core_metadata_elements){
  if(grepl(".RDS",f)){photos_metadata <- readRDS(paste0(images_directory,"/METADATA/exif/",f))}
}
attr(photos_metadata$DateTimeOriginal,"tzone")
head(photos_metadata)
# load the exif metadata in the SQL database
load_exif_metadata_in_database(con_Reef_database, codes_directory, photos_metadata, create_table=TRUE)

#  Check that the SQL database was properly loaded
check_database <- dbGetQuery(con_Reef_database, paste0("SELECT * FROM photos_exif_core_metadata WHERE session_id='",session_id,"' LIMIT 10"))
check_database
############################################################################################
###################### EXTRACT GPS TRACKS DATA AND LOAD THEM INTO POSTGRES DATABASE ########
############################################################################################ 
# set_time_zone <- dbGetQuery(con_Reef_database, "SET timezone = 'UTC+04:00'")
# check the number of GPS files for the session (sometimes more than one: battery issue..)

# define expected mime type for the search
file_type<-"RTK"
file_type<-"GPX"
file_type<-"TCX"
file_type<-"TCX"

# Use "dataframe_gps_files" to list all gps files
dataframe_gps_files <- return_dataframe_gps_files(images_directory,type=file_type)
number_row<-nrow(dataframe_gps_files)

# if only one GPS file
if(number_row==1){
gps_file <- paste(dataframe_gps_files$path,dataframe_gps_files$file_name,sep="/")
dataframe_gps_file <-NULL
# Use "dataframe_gps_file" to turn the gps file into a data frame
dataframe_gps_file <- return_dataframe_gps_file(wd=codes_directory, gps_file=gps_file, type=file_type, session_id=session_id,load_in_database=TRUE)
head(dataframe_gps_file)
nrow(dataframe_gps_file)
attr(dataframe_gps_file$time,"tzone")
duplicates <- distinct(dataframe_gps_file, time)
duplicates_number <- nrow(dataframe_gps_file)-nrow(duplicates)
paste0("the file has :", duplicates_number," duplicates")
load_gps_tracks_in_database(con_Reef_database, codes_directory, dataframe_gps_file, create_table=TRUE)
# generate a thumbnail of the map
# plot_tcx(gps_file,images_directory)
}

# if more than one (sometimes for some reasons, the same session has multiple GPS tracks) => iterate => difference between end point and start point > frequency
if(number_row>1){
  for (t in 1:number_row){
    row <- dataframe_gps_files[t,]
    path <- dataframe_gps_files$path[t]
    file_name <- dataframe_gps_files$file_name[t]
    gps_file = paste(path,file_name,sep="/")
    dataframe_gps_file <-return_dataframe_gps_file(codes_directory, gps_file, type=file_type, session_id,load_in_database=TRUE)
    attr(dataframe_gps_file$time,"tzone")
    duplicates <- distinct(dataframe_gps_file, time)
    duplicates_number <- nrow(dataframe_gps_file)-nrow(duplicates)
    paste0("the file has :", duplicates_number," duplicates")
    load_gps_tracks_in_database(con_Reef_database, codes_directory, dataframe_gps_file, create_table=TRUE)
  }
}
############################################################################################
###################### INFER LOCATION OF PHOTOS FROM GPS TRACKS TIMESTAMP  ########
############################################################################################ 
offset <- return_offset(con_Reef_database, session_metadata)
offset[[1]]
offset <- -1
# infer_photo_location_from_gps_tracks(con_Reef_database, images_directory, codes_directory,session_id , offset=offset_gsheet)
# infer_photo_location_from_gps_tracks(con_Reef_database, images_directory, codes_directory,session_id , offset=offset[[1]])
infer_photo_location_from_gps_tracks(con_Reef_database, images_directory, codes_directory,session_id , offset=offset)
# infer_photo_location_from_gps_tracks(con_Reef_database, images_directory, codes_directory,session_id , offset=4378)

############################################################################################
###################### CLOSE  ########
############################################################################################ 
dbDisconnect(con_Reef_database)

# 
# --select * FROM gps_tracks WHERE session_id='session_2019_02_16_kite_Le_Morne_la_Pointe' ORDER BY fid LIMIT 10
