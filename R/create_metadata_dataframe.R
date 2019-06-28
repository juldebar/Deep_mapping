# geoflow_entities
# https://docs.google.com/spreadsheets/d/1iG7i3CE0W9zVM3QxWfCjoYbqj1dQvKsMnER6kqwDiqM/edit#gid=0
# Geoflow entities Data Structure => Identifier	Title	Description	Subject	Creator	Date	Type	Language	SpatialCoverage	TemporalCoverage	Relation	Rights	Provenance	Data		
# This Data Structure => Identifier	Title	Description	Subject	Creator	Date	Type	Language	SpatialCoverage	TemporalCoverage	Relation	Rights	Provenance	Data	path	gps_file_name	Number_of_Pictures									
############################################################
################### Packages #######################
############################################################
rm(list=ls())

library(googledrive)
library(trackeR)
library(dplyr)
library(exifr)
library(data.table)
library(geoflow)
library(sf)
library(pdftools)
library(RgoogleMaps)
library(rosm)
library(prettymapr)


################### Set directories #######################
codes_directory <-"/home/julien/Bureau/CODES/Deep_mapping/"
setwd(codes_directory)
source(paste0(codes_directory,"R/functions.R"))
# working_directory <-  "/media/julien/Deep_Mapping_4To/data_deep_mapping/2019/A/pending/"
# working_directory <-  "/media/julien/Deep_Mapping_4To/data_deep_mapping/2019/A"
working_directory <- "/media/julien/Deep_Mapping_4To/data_deep_mapping/2018/A"
# working_directory <-"/media/julien/Deep_Mapping_4To/data_deep_mapping/2019/A/done"
setwd(working_directory)

sub_directories <- list.dirs(path=working_directory,full.names = TRUE,recursive = FALSE)
number_sub_directories <-length(sub_directories)

google_drive_path <- drive_get(id="1gUOhjNk0Ydv8PZXrRT2KQ1NE6iVy-unR")

################### Create a geoflow data frame and fill it with metadata #######################


metadata_sessions <- data.frame(Identifier=character(), Date=character(), path=character(), gps_file_name=character(), SpatialCoverage=character(), TemporalCoverage=character(),Relation=character(), Rights=character(), Provenance=character(), Data=character(), Number_of_Pictures=integer(), GPS_timestamp=character(),  Photo_GPS_timestamp=character())

for (i in 1:number_sub_directories){
  this_directory <- sub_directories[i]
  setwd(this_directory)
  session_id <- gsub(paste0(dirname(this_directory),"/"),"",this_directory)
  date <- gsub("_","-",substr(session_id,9,18))
  gps_file <- NULL
  spatial_extent <- NULL
  temporal_extent <- NULL
  Number_of_Pictures <- NULL
  rights <-""
#   rights <-"use:terms1;
#   use:citation1;
# use:disclaimer1;
# useConstraint:copyright;
# useConstraint:license;
# accessConstraint:copyright;
# otherConstraint:web use;"
  provenance <-""
#   provenance <-"statement:My data management workflow;
# process:
# rationale1[description1],
# rationale2[description2],
# rationale3[description3]
# processor:
# emmanuel.blondel1@gmail.com,
# julien.barde@ird.fr,
# wilfried.heintz@inra.fr"
  
  GPS_timestamp <- NULL
  Photo_GPS_timestamp <- NULL
  
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
    # geoflow entities data structure => 2007-03-01T13:00:00Z/2008-05-11T15:30:00Z
    first_picture_metadata <- read_exif(paste(this_directory,"DCIM", files[1],sep="/"))
    start_date<- as.POSIXct(first_picture_metadata$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
    start_date<-paste0(gsub(" ","T",start_date),"Z")
    end_date<- as.POSIXct(read_exif(paste(this_directory,"DCIM",files[Number_of_Pictures],sep="/"))$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
    end_date<-paste0(gsub(" ","T",end_date),"Z")
    # temporal_extent <- paste0("start=", start_date,";end=",end_date)
    temporal_extent <- paste0(start_date,"/",end_date)
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
  file_type<-"TCX" #  "GPX"  "TCX" "RTK" "videos" "aerial"
  dataframe_gps_files <- return_dataframe_gps_files(this_directory,type=file_type)
  if(is.null(dataframe_gps_files)){
    file_type<-"GPX"
    dataframe_gps_files <- return_dataframe_gps_files(this_directory,type=file_type)
    }
  number_row<-nrow(dataframe_gps_files)
  if(number_row>0){
    
    xmin <- NULL
    xmax <- NULL
    ymin <- NULL
    ymax <- NULL
    
    for (t in 1:number_row){
      
      gps_file <- paste(dataframe_gps_files$path[t],dataframe_gps_files$file_name[t],sep="/")
      dataframe_gps_file <-NULL
      dataframe_gps_file <- return_dataframe_gps_file(wd=codes_directory, gps_file=gps_file, type=file_type, session_id=session_id)
#       head(dataframe_gps_file)
      xmin <- min(dataframe_gps_file$longitude)
      xmax <- max(dataframe_gps_file$longitude)
      ymin <- min(dataframe_gps_file$latitude)
      ymax <- max(dataframe_gps_file$latitude)
      spatial_extent <- WKT <- paste("SRID=4326;POLYGON((",xmin,ymin,",",xmin,ymax,",",xmax,ymax,",",xmax,ymin,",",xmin,ymin,"))",sep=" ")
      
#       jpeg(paste0(session_id,".jpg"))
#       bmaps.plot(bbox, type = "Aerial",res=300,zoomin=-1,stoponlargerequest=FALSE)
#       # prettymap(bmaps.plot(bbox, type = "Aerial",zoomin=-1,stoponlargerequest=FALSE),res=300, scale.style="ticks", scale.tick.cex=0.5)
#       osm.points(dataframe_gps_file$longitude,dataframe_gps_file$latitude, col="yellow",pch=18, cex=0.5)
#       dev.off()

      this_wd <- getwd()
      setwd(as.character(dataframe_gps_files$path[t]))
      
      gps_points <- st_as_sf(dataframe_gps_file, coords = c("longitude", "latitude"),crs = 4326)
      bbox <- makebbox(ymax,xmax,ymin,xmin)
      bbox <- makebbox(ymax+0.03,xmax+0.03,ymin-0.03,xmin-0.03)
      bbox
      
      pdf(paste0(session_id,".pdf"))
      bmaps.plot(bbox, type = "Aerial",res=600,zoomin=-1,stoponlargerequest=FALSE)
      # prettymap(bmaps.plot(bbox, type = "Aerial",zoomin=-1,stoponlargerequest=FALSE),res=300, scale.style="ticks", scale.tick.cex=0.5)
      osm.points(dataframe_gps_file$longitude,dataframe_gps_file$latitude, col="yellow",pch=18, cex=0.5)
      dev.off()
      
      # https://cran.r-project.org/web/packages/pdftools/pdftools.pdf
      pdf_convert(paste0(session_id,".pdf"), pages = NULL,format = "jpeg",dpi = 600,filenames=paste0(session_id,".jpeg"))
      
      file_name <-paste0(session_id,".jpeg")
      google_drive_file <- upload_google_drive(google_drive_path,file_name)
      google_drive_file_url <- paste0("https://drive.google.com/open?id=",google_drive_file$id)
      google_drive_file %>% drive_reveal("permissions")
      google_drive_file %>% drive_reveal("published")
      google_drive_file <- google_drive_file %>% drive_share(role = "reader", type = "anyone")
      google_drive_file %>% drive_reveal("published")
      # google_drive_file <- drive_publish(as_id(google_drive_file$id))
      
      
      file_name <- gsub("\\.","_",dataframe_gps_files$file_name[t])
      # file_name <- gsub("x","x.csv",file_name)
      shape_file <- write_shp_from_csv(file_name)
      # qgs_template <- "/home/julien/Bureau/CODES/Deep_mapping/template/qgis_project_csv.qgs"
      qgs_template <- "/home/julien/Bureau/CODES/Deep_mapping/template/qgis_project_shapefile_new.qgs"
      write_qgis_project(session_id, qgs_template,shape_file,xmin,xmax,ymin,ymax)
      setwd(this_wd)

    }
  }else{
    (cat("No GPS file when looking for TCX or GPX or RTK files"))
    gps_file <- "No GPS file"
    spatial_extent <- "No GPS file"
  }
  
  files <- NULL
  con <- file(paste(this_directory,"LABEL","tag.txt",sep="/"),"r")
  first_line <- readLines(con,n=1)
  close(con)
  
  first_line <- sub('.*session', 'session', first_line)
  photo_calibration_metadata <- read_exif(paste(gsub(session_id,"",this_directory), sub(' => .*', '', first_line),sep=""))
  Photo_GPS_timestamp<- as.POSIXct(photo_calibration_metadata$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
  
  GPS_timestamp <- sub('.* => ', '', first_line)
  GPS_timestamp <- sub('secs\").*', 'secs\")', GPS_timestamp)
  offset <- GPS_timestamp
  
  
  title <- gsub("_"," ",session_id)
  title <- gsub("201"," of the 201",title)
  description <- paste0("abstract:This dataset is made of ",Number_of_Pictures," pictures which have been collected during the ", title)
  download_google_drive_file_url <- gsub("open\\?id","uc?id",google_drive_file_url)
  relation <-paste0("thumbnail:",session_id,"@",download_google_drive_file_url)
  
  # data <-paste0("identifier:",session_id,";\nsource:",gps_file,";\nsourceName:",session_id,";\ntype:dataset;\nupload:true;")
  # data <-paste0("source:file:///tmp/dessin.pdf;\nsourceName:",session_id,";\ntype:other;\nupload:true;")
  data <-paste0("source:http://www.fao.org/3/i7805en/I7805EN.pdf;\nsourceName:",session_id,";\ntype:other")
  
  ############################################################
  ################### CREATE DATAFRAME #######################
  ############################################################
  # metadata_sessions <- data.frame(Identifier=character(), Date=character(), path=character(), gps_file_name=character(), SpatialCoverage=character(), TemporalCoverage=character(),Relation=character(), Rights=character(), Provenance=character(), Data=character(), Number_of_Pictures=integer(), GPS_timestamp=character(),  Photo_GPS_timestamp=character())
  newRow <- data.frame(Identifier=paste0("id:",session_id,";"),Title=title,	Description=description, Date=date,path=this_directory,gps_file_name=gps_file,SpatialCoverage=spatial_extent, TemporalCoverage=temporal_extent, Relation=relation,Rights=rights, Provenance=provenance, Data=data, Number_of_Pictures=Number_of_Pictures, GPS_timestamp=GPS_timestamp, Photo_GPS_timestamp=Photo_GPS_timestamp)
  metadata_sessions <- rbind(metadata_sessions,newRow)
}

metadata_sessions$Subject <- "GENERAL:Mauritius,coral reef,photos,deep learning,kite surfing,coral reef habitats;"
metadata_sessions$Creator <- "owner:emmanuel.blondel1@gmail.com;\npointOfContact:julien.barde@ird.fr,wilfried.heintz@inra.fr;"
metadata_sessions$Type <- "dataset"
metadata_sessions$Language <- "eng"

names(metadata_sessions)
head(metadata_sessions)
# Identifier	Title	Description	Subject	Creator	Date	Type	Language	SpatialCoverage	TemporalCoverage	Relation	Rights	Provenance	Data	path	gps_file_name	Number_of_Pictures	GPS_timestamp	Photo_GPS_timestamp
# Identifier	Title	Description	Subject	Creator	Date	Type	Language	SpatialCoverage	TemporalCoverage	Relation	Rights	Provenance	Data	Node_ID	Vid	DOI	Reference	IRD_reference	IOTC_title	Meeting	Meeting_session	Meeting_year	Authors	All_taxonomy_terms	File	Path	Abstract		
metadata_sessions <- metadata_sessions[,c(1,2,3,16,17,4,18,19,7,8,9,10,11,12,5,6,13,14,15)]

setwd(working_directory)
local_file_path <-paste0(session_id,".jpeg")
local_file_path <-"metadata_sessions.csv"
file_name <-"metadata_sessions.csv"
write.csv(metadata_sessions,file = file_name,row.names = F)
nrow(metadata_sessions)
sum(metadata_sessions$Number_of_Pictures)

metadata_sessions_google_drive_file <- upload_google_drive(google_drive_path,file_name)
metadata_sessions_google_drive_file_url <- paste0("https://drive.google.com/open?id=",google_drive_file$id)
google_drive_file_url <- paste0("https://drive.google.com/open?id=",google_drive_file$id)
google_drive_file %>% drive_reveal("permissions")
google_drive_file %>% drive_reveal("published")
google_drive_file <- google_drive_file %>% drive_share(role = "reader", type = "anyone")
google_drive_file %>% drive_reveal("published")

########################################################################################################################
################### Run geoflow #######################
########################################################################################################################
setwd(paste0(codes_directory,"R/geoflow"))
executeWorkflow(file = "Deep_mappping_worflow.json")
########################################################################################################################
################### Create a view for each session with the track of the survey as a polyline #######################
########################################################################################################################
# con_Reef_database <- dbConnect(DRV, user=User, password=Password, dbname=Dbname, host=Host)
# template_query_create_view <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/create_view_session_template.sql"), collapse=" ")
# query_metadata <- "SELECT * FROM metadata"
# get_metadata  <- dbGetQuery(con_Reef_database,query_metadata)
# number_row<-nrow(get_metadata)
# for (i in 1:number_row) {
#   query_create_view<- gsub("view_session_2018_03_31_kite_Le_Morne",get_metadata$related_view_name[i],template_query_create_view)
#   query_create_view<- gsub("session_2018_03_31_kite_Le_Morne",get_metadata$identifier[i],template_query_create_view)
#   create_view  <- dbGetQuery(con_Reef_database,query_create_view)
# }

# http://pierreroudier.github.io/teaching/20170626-Pedometrics/20170626-soil-data.html


