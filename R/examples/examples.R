rm(list=ls())
############################################################################################
######################SET DIRECTORIES & LOAD SOURCES & CONNECT DATABASE##################################
############################################################################################
images_directory <- "/media/julien/39160875-fe18-4080-aab7-c3c3150a630d/julien/go_pro_all/session_2018_03_17_kite_Anse_La_Raie"
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

exif_core_metadata_elements <- list.files(path = paste0(images_directory,"/METADATA/exif"), pattern = "Core_Exif_metadata_")
photos_metadata <-NULL
photos_metadata <- readRDS(paste0(images_directory,"/METADATA/exif/",exif_core_metadata_elements))
load_exif_metadata_in_database(con_Reef_database, codes_directory, photos_metadata, create_table=TRUE)

# check_database <- dbSendQuery(con_Reef_database, paste0("SELECT * FROM gps_tracks WHERE session_id='",session_id,"' LIMIT 10"))
check_database <- dbGetQuery(con_Reef_database, paste0("SELECT * FROM photos_exif_core_metadata WHERE session_id='",session_id,"' LIMIT 10"))
check_database

############################################################################################
###################### EXTRACT GPS TRACKS DATA AND LOAD THEM INTO POSTGRES DATABASE ########
############################################################################################ 
dataframe_tcx_files <- return_dataframe_tcx_files(images_directory)
tcx_file <- paste(dataframe_tcx_files$path,dataframe_tcx_files$file_name,sep="/")
type<-"TCX"
dataframe_gps_file <-return_dataframe_gps_file(codes_directory, tcx_file, type, session_id,load_in_database=FALSE)
duplicates <- distinct(dataframe_gps_file, time)
nrow(dataframe_gps_file)-nrow(duplicates)

load_gps_tracks_in_database(con_Reef_database, codes_directory, dataframe_gps_file, create_table=TRUE)

plot_tcx(tcx_file,images_directory)



number_row<-nrow(dataframe_tcx_files)
for (t in 1:number_row){
  row <- dataframe_tcx_files[t,]
  session <- "sess  ion_2018_01_01_kite_Le_Morne"
  path <- dataframe_tcx_files$path[t]
  file_name <- dataframe_tcx_files$file_name[t]
  file = paste(path,file_name,sep="/")
  
  runDF <- NULL
  #   # runDF <- readTCX(file=file, timezone = "GMT")
  runDF <- readTCX(file="./R/examples/11597621537.tcx")
  runDF$session <- session
  runDF$time <- as.POSIXct(runDF$time, "%Y:%m:%d %H:%M:%S", tz="UTC")
  select_columns = subset(runDF, select = c(session,latitude,longitude,altitude,time,heart.rate))
  GPS_tracks_values = rename(select_columns, session_id=session, latitude=latitude,longitude=longitude, altitude=altitude, heart_rate=heart.rate, time=time)
  names(GPS_tracks_values)
  # GPS_tracks_values$fid <-c(1:nrow(GPS_tracks_values))
  # GPS_tracks_values <- GPS_tracks_values[,c(6,1,2,3,4,5)]
  # GPS_tracks_values$time <- as.POSIXct(GPS_tracks_values$time, "%Y-%m-%d %H:%M:%OS")
  GPS_tracks_values$the_geom <- NA
  load_gps_tracks_in_database(con_Reef_database, codes_directory, GPS_tracks_values, create_table=TRUE)
}

############################################################################################
###################### INFER LOCATION OF PHOTOS FROM GPS TRACKS TIMESTAMP  ########
############################################################################################ 
# offset <- return_offset(con_Reef_database, session_metadata)-3600
offset <- return_offset(con_Reef_database, session_metadata) +3600
query <- NULL
query <- paste(readLines(paste0(codes_directory,"SQL/template_interpolation_between_closest_GPS_POINTS.sql")), collapse=" ")
query <- gsub("session_2018_03_24_kite_Le_Morne",session_id,query)
if(offset < 0){
  query <- gsub("- interval","+ interval",query)
  query <- gsub("41",abs(offset)-1,query)
  query <- gsub("42",abs(offset),query)
}else{
query <- gsub("41",abs(offset)-1,query)
query <- gsub("42",abs(offset),query)
}
writeLines(query)
infer_location <- dbGetQuery(con_Reef_database, query)
head(infer_location)
write.csv(infer_location, "/tmp/photos_location.csv",row.names = F)
infer_location
# infer_photo_location_from_gps_tracks(con_Reef_database, codes_directory, session_id=session)



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



ogr2ogr -f GPX points.gpx PG:'host=reef-db.d4science.org user=Reef_admin password=4b0a6dd24ac7b79 dbname=Reef_database' -sql "select * from gps_tracks where session_id='session_2018_03_31_kite_Le_Morne' LIMIT 100"


dsn <- paste0("PG:dbname='",Dbname,"' host='",Host,"' port='5432' user='",User,"' password='",Password," ' \" ")
obj <- rgdal::readOGR(dsn=dsn, layer = "photos_exif_core_metadata") 
spdf <- dbReadSpatial(con_Reef_database, schemaname="public", tablename="gps_tracks", geomcol="the_geom")
buffer <- rgdal::readOGR("PG:dbname=Reef_database", "gps_tracks")

############################################################################################
###################### CLOSE  ########
############################################################################################ 

dbDisconnect(con_Reef_database)
