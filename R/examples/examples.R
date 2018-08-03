rm(list=ls())
############################################################################################
######################SET DIRECTORIES & LOAD SOURCES & CONNECT DATABASE##################################
############################################################################################
codes_directory <-"/home/julien/Bureau/CODES/Deep_mapping/"
setwd(codes_directory)
source(paste0(codes_directory,"R/credentials_databases.R"))
source(paste0(codes_directory,"R/functions.R"))
con_Reef_database <- dbConnect(DRV, user=User, password=Password, dbname=Dbname, host=Host)
images_directory <- "/media/julien/39160875-fe18-4080-aab7-c3c3150a630d/julien/go_pro_all/session_2018_01_01_kite_Le_Morne"
session_id <-"session_2018_01_01_kite_Le_Morne"

#SELECT "DateTimeOriginal" FROM photos_exif_core_metadata WHERE "FileName"='G0020045.JPG'
photo_time <- as.POSIXct("2015-01-01 05:23:30+01") 
photo_time <- "2015-01-01 05:23:30" 

GPS_time <- 
GPS_time <-  as.POSIXct("2018-01-01 14:47:00", tz="Indian/Mauritius")
exif_metadata$DateTimeOriginal = as.POSIXct(unlist(exif_metadata$DateTimeOriginal),"%Y:%m:%d %H:%M:%S", tz="Indian/Mauritius")


offset <-difftime(photo_time, GPS_time, units="secs")
offset
############################################################################################
###################### EXTRACT CSV METADATA ##################################
############################################################################################
template_df <- read.csv(paste0(codes_directory,"CSV/All_Exif_metadata_template.csv"),stringsAsFactors = FALSE)
# sapply(template_df,class)
# head(template_df)
last_metadata_pictures <- extract_exif_metadata_in_csv(images_directory=images_directory, template_df, load_metadata_in_database=FALSE)
head(last_metadata_pictures)
sapply(last_metadata_pictures,class)
class(last_metadata_pictures$LightValue)
last_metadata_pictures$DateTimeOriginal
last_metadata_pictures$GPSDateTime
# SUR CSV ALL METADATA
# CSV_total$ThumbnailImage[1] 
# CSV_total$ThumbnailOffset[1]
# CSV_total$ThumbnailLength[1]
exif_core_metadata_elements <- list.files(path = paste0(images_directory,"/METADATA/exif"), pattern = "Core_Exif_metadata_")
photos_metadata <- readRDS(exif_core_metadata_elements)

load_exif_metadata_in_database(con_Reef_database, codes_directory, photos_metadata, create_table=TRUE)
############################################################################################
###################### EXTRACT GPS TRACKS DATA AND LOAD THEM INTO POSTGRES DATABASE ########
############################################################################################ 
dataframe_tcx_files <- return_dataframe_tcx_files(images_directory)

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

# query <- paste(readLines(paste0(codes_directory,"SQL/interpolation_between_closest_GPS_POINTS.sql")), collapse=" ")
# query <- gsub("","",query)

# infer_photo_location_from_gps_tracks(con_Reef_database, codes_directory, session_id=session)



############################################################################################
###################### CLOSE  ########
############################################################################################ 
  
dbDisconnect(con_Reef_database)





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
###################### EXTRACT EXIF METADATA FROM GOPRO DIRECTORY  ########
############################################################################################ 
file <-"/media/julien/39160875-fe18-4080-aab7-c3c3150a630d/julien/go_pro_all/raw_201707111046-4.csv"
tracks<-read_rtk(file_rtk=file)
head(tracks)
sapply(tracks,class)

# select_columns = subset(tracks, select = c(ratio,latitude,longitude,altitude,time,heart.rate))
select_columns = subset(tracks, select = c(ratio,latitude,longitude,height,GPST,age))
GPS_tracks_values = rename(select_columns, session_id=ratio, latitude=latitude,longitude=longitude, altitude=height, heart_rate=age, time=GPST)
names(GPS_tracks_values)
sapply(GPS_tracks_values,class)

# GPS_tracks_values$fid <-c(1:nrow(GPS_tracks_values))
# GPS_tracks_values <- GPS_tracks_values[,c(6,1,2,3,4,5)]
GPS_tracks_values$session_id <- 1111
GPS_tracks_values$heart_rate <- as.numeric(GPS_tracks_values$heart_rate)
GPS_tracks_values$time <- as.POSIXct(GPS_tracks_values$time, "%Y/%m/%d %H:%M:%OS")
GPS_tracks_values$the_geom <- NA
head(GPS_tracks_values)

load_gps_tracks_in_database(con_Reef_database, codes_directory, GPS_tracks_values, create_table=TRUE)
