############################################################
################### Packages #######################
############################################################
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
################### Create a geoflow data frame to store metadata #######################
# session_directory <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/good/database/session_2019_06_23_kite_Le_Morne_One_Eye"
# google_drive_path <- drive_get(id="1gUOhjNk0Ydv8PZXrRT2KQ1NE6iVy-unR")
# google_drive_file_url <- paste0("https://drive.google.com/open?id=",google_drive_path$id)
# metadata <- get_session_metadata(session_directory, google_drive_path,metadata_sessions)
# metadata
################### Function to fill the geoflow data frame with metadata #######################
get_session_metadata <- function(session_directory, google_drive_path, metadata_sessions,type_images="gopro"){
    
  ################### Set directories #######################
  this_directory <- session_directory
  setwd(this_directory)
  sub_directories <- list.dirs(path=this_directory,full.names = TRUE,recursive = FALSE)
  number_sub_directories <-length(sub_directories)
  
  ################### Set static metadata elements #######################
  session_id <- gsub(" ","_",gsub(paste0(dirname(this_directory),"/"),"",this_directory))
  
  title <- gsub("201"," of the 201",gsub("_"," ",session_id))
  subject <- "GENERAL:Mauritius,coral reef,photos,deep learning,kite surfing,coral reef habitats;"
  creator <- "owner:emmanuel.blondel1@gmail.com;\npointOfContact:julien.barde@ird.fr,wilfried.heintz@inra.fr"
  type <- "dataset"
  language <- "eng"
  date <- gsub("_","-",substr(session_id,9,18))
  provenance <-"statement:This is some data quality statement providing information on the provenance"
  source <-"my kite;"
  format <-"JPEG"
  gps_file <- NULL
  spatial_extent <- NULL
  temporal_extent <- NULL
  Number_of_Pictures <- NULL
  rights <-"use:terms1;"
  GPS_timestamp <- NULL
  Photo_GPS_timestamp <- NULL
  
  ################### Calculate dynamicmetadata elements #######################
  ################### Number of Photos #######################
  files <- NULL
  files <- list.files(path = paste(this_directory,"DCIM",sep="/"), pattern = "*.JPG",recursive = TRUE)
  if(length(files)>0){
    Number_of_Pictures <- length(files)
    description <- paste0("abstract:This dataset is made of ",Number_of_Pictures," pictures which have been collected during the ", title)
    ############################################################
    ################### TEMPORAL COVERAGE ######################
    ############################################################
    # geoflow entities data structure => 2007-03-01T13:00:00Z/2008-05-11T15:30:00Z
    first_picture_metadata <- read_exif(paste(this_directory,"DCIM", files[1],sep="/"))
    start_date<- as.POSIXct(first_picture_metadata$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
    start_date<-paste0(gsub(" ","T",start_date),"Z")
    end_date<- as.POSIXct(read_exif(paste(this_directory,"DCIM",files[Number_of_Pictures],sep="/"))$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
    end_date<-paste0(gsub(" ","T",end_date),"Z")
    temporal_extent <- paste0(start_date,"/",end_date)
    }else{
      Number_of_Pictures <- "No Photos"
      temporal_extent <- "No Photos"
      cat(Number_of_Pictures)
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
      # #       head(dataframe_gps_file)
      #       xmin <- min(dataframe_gps_file$longitude)
      #       xmax <- max(dataframe_gps_file$longitude)
      #       ymin <- min(dataframe_gps_file$latitude)
      #       ymax <- max(dataframe_gps_file$latitude)
      #       spatial_extent <- paste("SRID=4326;POLYGON((",xmin,ymin,",",xmin,ymax,",",xmax,ymax,",",xmax,ymin,",",xmin,ymin,"))",sep=" ")
      if(grepl(pattern = ".tcx",gps_file)){
        spatial_extent <- tcx_to_wkt(gps_file, dTolerance = 0.00005)
      }else{
        spatial_extent <- gpx_to_wkt(gps_file, dTolerance = 0.00005)
      }
      # spatial_extent_geom <- sf::st_as_sfc(spatial_extent,wkt = "geom")
      # spatial_extent_geom <- sf::st_as_sfc(paste0("SRID=4326;",spatial_extent))
      spatial_extent_geom <- sf::st_as_sfc(spatial_extent)
      simplified_spatial_extent <- sf::st_as_sfc(spatial_extent) %>% st_simplify(dTolerance = 0.00005)  %>% st_as_text()
      
      
      # class(spatial_extent_geom)
      latitude <- as.data.frame(st_coordinates(spatial_extent_geom))$Y
      longitude <- as.data.frame(st_coordinates(spatial_extent_geom))$X
      # class(st_coordinates(spatial_extent_geom))
      
      #       jpeg(paste0(session_id,".jpg"))
      #       bmaps.plot(bbox, type = "Aerial",res=300,zoomin=-1,stoponlargerequest=FALSE)
      #       # prettymap(bmaps.plot(bbox, type = "Aerial",zoomin=-1,stoponlargerequest=FALSE),res=300, scale.style="ticks", scale.tick.cex=0.5)
      #       osm.points(dataframe_gps_file$longitude,dataframe_gps_file$latitude, col="yellow",pch=18, cex=0.5)
      #       dev.off()
      
      this_wd <- getwd()
      setwd(as.character(dataframe_gps_files$path[t]))
      
      # gps_points <- st_as_sf(dataframe_gps_file, coords = c("longitude", "latitude"),crs = 4326)
      # bbox <- makebbox(ymax,xmax,ymin,xmin)
      # bbox <- makebbox(ymax+0.03,xmax+0.03,ymin-0.03,xmin-0.03)
      bbox <- st_bbox(spatial_extent_geom)
      
      ######################## write a pdf and a jpeg file to get an overview of the spat https://cran.r-project.org/web/packages/rosm/rosm.pdf
      pdf(paste0(session_id,".pdf"))
      if(grepl("odrigue",session_id)){
        zoomin=-1
        type = "hikebike"
        osm.plot(bbox, type = type,res=600,zoomin=zoomin,stoponlargerequest=FALSE)
      }else{
        zoomin=-1
        type = "Aerial"
        bmaps.plot(bbox, type = type,res=600,zoomin=zoomin,stoponlargerequest=FALSE)
        }
      # prettymap(bmaps.plot(bbox, type = "Aerial",zoomin=-1,stoponlargerequest=FALSE),res=300, scale.style="ticks", scale.tick.cex=0.5)
      # osm.points(spatial_extent_geom$longitude,dataframe_gps_file$latitude, col="yellow",pch=18, cex=0.5)
      osm.points(longitude,latitude, col="yellow",pch=18, cex=0.5)
      dev.off()
      
      # https://cran.r-project.org/web/packages/pdftools/pdftools.pdf
      pdf_convert(paste0(session_id,".pdf"), pages = NULL,format = "jpeg",dpi = 600,filenames=paste0(session_id,".jpeg"))
      
      pdf_uri <- NULL
      jpeg_uri <-NULL
      pdf_uri <- gsub("open\\?id","uc?id",paste0("https://drive.google.com/open?id=",upload_file_on_drive_repository(google_drive_path,paste0(session_id,".pdf"))))
      jpeg_uri <-gsub("open\\?id","uc?id",paste0("https://drive.google.com/open?id=",upload_file_on_drive_repository(google_drive_path,paste0(session_id,".jpeg"))))
      
      relation <-paste0("thumbnail:",session_id,"@",jpeg_uri)
      relation <-paste0(relation,";\nhttp:map(pdf)@",pdf_uri)
      # data <-paste0("uploadType:dbview;\n:",pdf_uri)
      data <-paste0('source:mydatasource;\nuploadType:dbquery;\ndbquery:"SELECT * FROM', session_id,';\nlayername:',session_id,';\nstyle:line_grid5x5')
      # data <-paste0("source:file:///tmp/dessin.pdf;\nsourceName:",session_id,";\ntype:other;\nupload:true;")
      
      ######################## store spatial data in a shape file
      # file_name <- paste0("photos_location_",session_id)
      # if (!file.exists(paste0(file_name,".shp"))){
      #   shape_file <- write_shp_from_csv(file_name)
      # }else{
      #   paste0("\n Le fichier ", file_name,".shp  existe déjà !\n ")
      # }
      
      ######################## write a qgis project to visualize the shape file
      # qgs_template <- "/home/julien/Bureau/CODES/Deep_mapping/template/qgis_project_csv.qgs"
      qgs_template <- "/home/julien/Bureau/CODES/Deep_mapping/template/qgis_project_shapefile_new.qgs"
      # write_qgis_project(session_id, qgs_template,shape_file,xmin,xmax,ymin,ymax)
      setwd(this_wd)
      
    }
  }else{
    cat("No GPS file when looking for TCX or GPX or RTK files")
    cat(paste0("\n Pas de dossier'GPS' dans ", this_directory,"\n"))
    gps_file <- "No GPS file"
    spatial_extent <- "No GPS file"
  }
  files <- NULL
  
  if(type_images=="drone"){
    offset=0
  }else{
    con <- file(paste(this_directory,"LABEL","tag.txt",sep="/"),"r")
    first_line <- readLines(con,n=1)
    close(con)
    
    first_line <- sub('.*session', 'session', first_line)
    photo_calibration_metadata <- read_exif(paste(gsub(session_id,"",this_directory), sub(' => .*', '', first_line),sep=""))
    Photo_GPS_timestamp<- as.POSIXct(photo_calibration_metadata$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
    
    GPS_timestamp <- sub('.* => ', '', first_line)
    GPS_timestamp <- sub('secs\").*', 'secs\")', GPS_timestamp)
    offset <- GPS_timestamp
    #############################
  }
    
###############################
  ################### CREATE DATAFRAME #######################
  ############################################################
  
  
  newRow <- data.frame(Identifier=paste0("id:",session_id),
                       Description=description,
                       Title=title,
                       Subject=subject,
                       Creator=creator,
                       Date=date,
                       Type=type,
                       SpatialCoverage=paste0("SRID=4326;",simplified_spatial_extent),
                       TemporalCoverage=temporal_extent,
                       Language=language,
                       Relation=relation,
                       Rights=rights,
                       Source=source,
                       Provenance=provenance,
                       Format=format,
                       Data=data,
                       path=this_directory,
                       gps_file_name=gps_file,
                       Number_of_Pictures=Number_of_Pictures,
                       GPS_timestamp=GPS_timestamp,
                       Photo_GPS_timestamp=Photo_GPS_timestamp,
                       # geometry=spatial_extent_geom
                       # geometry=st_as_binary(spatial_extent_geom)
                       geometry=NA
                       )
  
  metadata_sessions <- rbind(metadata_sessions,newRow)
  # metadata_sessions <- metadata_sessions[,c(1,2,3,16,17,4,18,19,7,8,9,10,11,12,5,6,13,14,15)]
  
  setwd(session_directory)
  return(metadata_sessions)
  #end function 
}