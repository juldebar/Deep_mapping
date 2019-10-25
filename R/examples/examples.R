rm(list=ls())
############################################################################################
######################SET DIRECTORIES & LOAD SOURCES & CONNECT DATABASE##################################
############################################################################################
codes_directory <-"~/Bureau/CODES/Deep_mapping/"
# codes_directory <-"~/Deep_mapping-master/"
setwd(codes_directory)
source(paste0(codes_directory,"R/functions.R"))
source(paste0(codes_directory,"R/credentials_databases.R"))
con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)
# set_time_zone <- dbGetQuery(con_Reef_database, "SET timezone = 'UTC+04:00'")
create_table_gps_tracks=TRUE
if(create_table_gps_tracks==TRUE){
  query_create_table_gps_tracks <- paste(readLines(paste0(codes_directory,"SQL/create_tables_GPS_tracks.sql")), collapse=" ")
  create_table <- dbGetQuery(con_Reef_database,query_create_table_gps_tracks)
} 

Session_metadata_table <- "https://docs.google.com/spreadsheets/d/1MLemH3IC8ezn5T1a1AYa5Wfa1s7h6Wz_ACpFY3NvyrM/edit?usp=sharing"
Datasets <- as.data.frame(gsheet::gsheet2tbl(Session_metadata_table))
############################################################################################
######################SET DIRECTORIES & LOAD SOURCES & CONNECT DATABASE##################################
############################################################################################
images_directory <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/session_2019_09_11_kite_Le_Morne"
session_id <- gsub(paste0(dirname(images_directory),"/"),"",images_directory)
time_zone <- "Indian/Mauritius"

con <- file(paste0(images_directory,"/LABEL/tag.txt"),"r")
first_line <- readLines(con,n=1)
close(con)
offset <- eval(parse(text = sub(".*=> ","",first_line)))
offset

# strsplit(sub(".*=> difftime\\(","",first_line),",")[[1]][1]
# GPS_time <- strsplit(sub(".*=> difftime\\(","",first_line),",")[[1]][2]
# 
# session_metadata <-filter(Datasets, Identifier==session_id)
# photo_time <- "2019-09-23 14:18:10"
# photo_time_gsheet <- as.POSIXct(session_metadata$Photo_time, format="%Y-%m-%d %H:%M:%S",tz="UTC+04:00")
# attr(photo_time,"tzone")
# GPS_time <- "2019-09-23 14:18:00"
# GPS_time_gsheet <- as.POSIXct(session_metadata$GPS_time,format="%Y-%m-%d %H:%M:%S",tz="UTC")
# offset_gsheet <-difftime(photo_time_gsheet, GPS_time_gsheet, units="secs")
# offset_gsheet
# offset <-difftime(photo_time, GPS_time, units="secs")
# offset
# # file:///media/julien/disk/DCIM/175GOPRO/G0014747.JPG => heure 13:56:00, photo dim. 24 mars 2019, 13:55:58
# # offset <- return_offset(con_Reef_database, session_metadata)
# # offset[[1]]



########################################################################################################################################################################################
###################### EXTRACT exif metadata elements & store them in a CSV file & LOAD THEM INTO POSTGRES DATABASE  #########
########################################################################################################################################################################################
# extract exif metadata and store it into a CSV or RDS file
template_df <- read.csv(paste0(codes_directory,"CSV/All_Exif_metadata_template.csv"),stringsAsFactors = FALSE)
last_metadata_pictures <- extract_exif_metadata_in_csv(images_directory=images_directory, template_df, load_metadata_in_database=FALSE,time_zone=time_zone)
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
check_database$DateTimeOriginal

# sql_query <- paste0('select ("GPSDateTime" - "DateTimeOriginal") AS offset, * FROM photos_exif_core_metadata WHERE "GPSDateTime" IS NOT NULL AND session_id =\"',session_id,'\" LIMIT 10')
sql_query <- paste0('select ("GPSDateTime" - "DateTimeOriginal") AS offset, * FROM photos_exif_core_metadata WHERE "GPSDateTime" IS NOT NULL LIMIT 10')
offset_db <-NULL
check_offset_from_pictures <- dbGetQuery(con_Reef_database,sql_query)
offset_db <-difftime(check_offset_from_pictures$GPSDateTime, check_offset_from_pictures$DateTimeOriginal, units="secs")
offset_db
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
offset=offset
# offset=offset_db
photo_location <- infer_photo_location_from_gps_tracks(con_Reef_database, images_directory, codes_directory,session_id , offset=offset,create_view=TRUE)
head(photo_location,n = 50)
paste0("For a total of ",nrow(photos_metadata), " photos")
paste0(nrow(photo_location), " photos have been located from GPS tracks")
ratio = nrow(photos_metadata) / nrow(photo_location)
nrow(dataframe_gps_file)
#################################################################################################
###################### SMAKE A SUMMMARY OF TABLES CONTENT AND CLOSE DATABASE CONNEXION  ########
################################################################################################# 
dbDisconnect(con_Reef_database)
# --select COUNT(*) FROM gps_tracks WHERE session_id='session_2019_02_16_kite_Le_Morne_la_Pointe' ORDER BY fid LIMIT 10 
# SELECT  COUNT(*) FROM photos_exif_core_metadata WHERE session_id='session_2019_02_16_kite_Le_Morne_la_Pointe' ORDER BY ogc_fid LIMIT 10