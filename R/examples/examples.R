rm(list=ls())
############################################################################################
######################SET DIRECTORIES & LOAD SOURCES & CONNECT DATABASE##################################
############################################################################################
images_directory <- "/media/julien/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/gopro2/session_2018_03_10_kite_Le_Morne"
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
photo_time <- as.POSIXct(session_metadata$Photo_time, format="%Y-%m-%d %H:%M:%S", tz="Indian/Mauritius")
GPS_time <- as.POSIXct(session_metadata$GPS_time, tz="UTC")
attr(photo_time,"tzone")
offset_gsheet <-difftime(photo_time, GPS_time, units="secs")
offset_gsheet

# photo_time <- as.POSIXct(session_metadata$Photo_time, format="%Y-%m-%d %H:%M:%S %z", tz="Indian/Mauritius")
#SELECT "DateTimeOriginal" FROM photos_exif_core_metadata WHERE "FileName"='G0020045.JPG'
# photo_time <- as.POSIXct("2015-01-01 05:23:30+01") 
# photo_time <- "2015-01-01 05:23:30" 
# exif_metadata$DateTimeOriginal = as.POSIXct(unlist(exif_metadata$DateTimeOriginal),"%Y:%m:%d %H:%M:%S", tz="Indian/Mauritius")
############################################################################################
###################### EXTRACT CSV METADATA ##################################
############################################################################################
template_df <- read.csv(paste0(codes_directory,"CSV/All_Exif_metadata_template.csv"),stringsAsFactors = FALSE)
# sapply(template_df,class)
# head(template_df)
last_metadata_pictures <- extract_exif_metadata_in_csv(images_directory=images_directory, template_df, load_metadata_in_database=FALSE)
attr(last_metadata_pictures$DateTimeOriginal,"tzone")

exif_core_metadata_elements <- list.files(path = paste0(images_directory,"/METADATA/exif"), pattern = "Core_Exif_metadata_")
photos_metadata <-NULL
photos_metadata <- readRDS(paste0(images_directory,"/METADATA/exif/",exif_core_metadata_elements))
attr(photos_metadata$DateTimeOriginal,"tzone")

load_exif_metadata_in_database(con_Reef_database, codes_directory, photos_metadata, create_table=FALSE)

# check_database <- dbSendQuery(con_Reef_database, paste0("SELECT * FROM gps_tracks WHERE session_id='",session_id,"' LIMIT 10"))
check_database <- dbGetQuery(con_Reef_database, paste0("SELECT * FROM photos_exif_core_metadata WHERE session_id='",session_id,"' LIMIT 10"))
check_database
set_time_zone <- dbGetQuery(con_Reef_database, "SET timezone = 'UTC'")



############################################################################################
###################### EXTRACT GPS TRACKS DATA AND LOAD THEM INTO POSTGRES DATABASE ########
############################################################################################ 
# check the number of tcx files for the session (sometimes more than one: battery issue..)
dataframe_tcx_files <- return_dataframe_tcx_files(images_directory)
number_row<-nrow(dataframe_tcx_files)
# if only one GPS file
type<-"TCX"
if(number_row==1){
  tcx_file <- paste(dataframe_tcx_files$path,dataframe_tcx_files$file_name,sep="/")
  dataframe_gps_file <-return_dataframe_gps_file(codes_directory, tcx_file, type, session_id,load_in_database=FALSE)
  attr(dataframe_gps_file$time,"tzone")
  duplicates <- distinct(dataframe_gps_file, time)
  duplicates_number <- nrow(dataframe_gps_file)-nrow(duplicates)
  paste0("the file has :", duplicates_number," duplicates")
  load_gps_tracks_in_database(con_Reef_database, codes_directory, dataframe_gps_file, create_table=FALSE)
  # load_gps_tracks_in_database(con_Reef_database, codes_directory, duplicates, create_table=TRUE)???
  # generate a thumbnail of the map
  # plot_tcx(tcx_file,images_directory)
}
# if more than one => iterate => difference between end point and start point > frequency
if(number_row>1){
  for (t in 1:number_row){
    row <- dataframe_tcx_files[t,]
    session <- "session_2018_01_01_kite_Le_Morne"
    path <- dataframe_tcx_files$path[t]
    file_name <- dataframe_tcx_files$file_name[t]
    tcx_file = paste(path,file_name,sep="/")
    dataframe_gps_file <-return_dataframe_gps_file(codes_directory, tcx_file, type, session_id,load_in_database=FALSE)
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
GPS_time <- as.POSIXct("2018-08-19 10:37:00", tz="UTC")
photo_time <- as.POSIXct("2018-08-19 14:40:19", tz="Indian/Mauritius")
GPS_time <- as.POSIXct("2018-06-30 12:13:00", tz="UTC")
photo_time <- as.POSIXct("2018-06-30 12:15:21", tz="UTC")

GPS_time <- as.POSIXct("2018-03-24 13:44:00", tz="UTC")
photo_time <- as.POSIXct("2018-03-24 13:44:42", tz="UTC")


offset <-difftime(photo_time, GPS_time, units="secs")
offset
# offset <- return_offset(con_Reef_database, session_metadata)-3600
offset <- return_offset(con_Reef_database, session_metadata) +3600
infer_photo_location_from_gps_tracks(con_Reef_database, images_directory, codes_directory, session_id, offset)
infer_photo_location_from_gps_tracks(con_Reef_database, images_directory, codes_directory, session_id, offset_gsheet)

# OLD
# query <- NULL
# query <- paste(readLines(paste0(codes_directory,"SQL/template_interpolation_between_closest_GPS_POINTS_new.sql")), collapse=" ")
# query <- gsub("session_2018_03_24_kite_Le_Morne",session_id,query)
# if(offset < 0){
#   query <- gsub("- interval","+ interval",query)
#   # query <- gsub("41",abs(offset)-1,query)
#   query <- gsub("42",abs(offset),query)
# }else{
#   # query <- gsub("41",abs(offset)-1,query)
#   query <- gsub("42",abs(offset),query)
# }
# writeLines(query)
# infer_location <- dbGetQuery(con_Reef_database, query)
# # infer_location <- infer_photo_location_from_gps_tracks(con_Reef_database, codes_directory, session_id=session, offset)
# head(infer_location)
# write.csv(infer_location, "/tmp/photos_location.csv",row.names = F)
# infer_location



############################################################################################
###################### EXTRACT EXIF METADATA FROM GOPRO DIRECTORY  ########
############################################################################################ 

rm(list=ls())
codes_directory <-"/home/julien/Bureau/CODES/Deep_mapping/"
image_directory <- "/media/julien/39160875-fe18-4080-aab7-c3c3150a630d/julien/go_pro_all/session_2018_01_01_kite_Le_Morne/DCIM/100GOPRO"
source(paste0(codes_directory,"test/extract_exif_metadata_in_this_directory.R"))
template_df <- read.csv(paste0(codes_directory,"CSV/All_Exif_metadata_template.csv"),stringsAsFactors = FALSE)
exif_metadata <- extract_exif_metadata_in_this_directory(images_directory=dirname(image_directory),image_directory,template_df, mime_type = "*.JPG")
metadata_pictures <- select(exif_metadata,
                            session_id,
                            session_photo_number,
                            relative_path,
                            FileName,
                            GPSLatitude,
                            GPSLongitude,
                            GPSDateTime,
                            DateTimeOriginal,
                            LightValue,
                            ImageSize,
                            Model,
                            geometry_postgis,
                            geometry_gps_correlate,
                            geometry_native                              
)
setwd("/tmp")
write.csv(metadata_pictures, "exif_metadata.csv",row.names = F)


############################################################################################
###################### CLOSE  ########
############################################################################################ 

tcx_file <-"./R/examples/11597621537.tcx"
type<-"TCX"
gpx_file <-"/media/julien/39160875-fe18-4080-aab7-c3c3150a630d/julien/go_pro_all/GO_PRO1/session_2017_11_05_kite_Le_Morne/GPS/10763408047.gpx"
type<-"GPX"
rtk_file <-"/home/julien/Téléchargements/raw_201707111046-4.csv"
type="RTK"
session_id="FAKE"
dataframe_gps_file <-NULL
dataframe_gps_file <- switch(type,
                             "RTK" = return_dataframe_gps_file(codes_directory, rtk_file, type, session_id,load_in_database=FALSE),
                             "TCX" = return_dataframe_gps_file(codes_directory, tcx_file, type, session_id,load_in_database=FALSE),
                             "GPX" = return_dataframe_gps_file(codes_directory, gpx_file, type, session_id,load_in_database=FALSE)
)
head(dataframe_gps_file)
nrow(dataframe_gps_file)
load_gps_tracks_in_database(con_Reef_database, codes_directory, dataframe_gps_file, create_table=FALSE)



# ogr2ogr -f GPX points.gpx PG:'host=reef-db.d4science.org user=Reef_admin password=4b0a6dd24ac7b79 dbname=Reef_database' -sql "select * from gps_tracks where session_id='session_2018_03_31_kite_Le_Morne' LIMIT 100"
# dsn <- paste0("PG:dbname='",Dbname,"' host='",Host,"' port='5432' user='",User,"' password='",Password," ' \" ")
# obj <- rgdal::readOGR(dsn=dsn, layer = "photos_exif_core_metadata") 
# spdf <- dbReadSpatial(con_Reef_database, schemaname="public", tablename="gps_tracks", geomcol="the_geom")
# buffer <- rgdal::readOGR("PG:dbname=Reef_database", "gps_tracks")

############################################################################################
###################### CLOSE  ########
############################################################################################ 

dbDisconnect(con_Reef_database)
