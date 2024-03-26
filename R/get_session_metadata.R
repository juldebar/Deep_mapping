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
# metadata <- data.frame(
#   Identifier=character(),
#   Description=character(),metadata_sessions=metadata_this_mission,type_images=type_images)
#   Title=character(),
#   Subject=character(),
#   Creator=character(),
#   Date=character(),
#   Type=character(),
#   SpatialCoverage=character(),
#   TemporalCoverage=character(),
#   Language=character(),
#   Relation=character(),
#   Rights=character(),  
#   Source=character(),  
#   Provenance=character(),
#   Format=character(),metadata_sessions=metadata_this_mission,type_images=type_images)
#   Data=character(),
#   path=character(),
#   gps_file_name=character(),
#   Number_of_Pictures=integer(),
#   GPS_timestamp=character(),
#   Photo_GPS_timestamp=character(),
#   geometry=character()
# )
# source(paste0(code_directory,"R/functions.R"))
# source(paste0(code_directory,"R/credentials_databases.R"))
# con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)
# metadata_this_mission <- get_session_metadata(con_database=con_Reef_database, session_directory=m, google_drive_path,metadata_sessions=metadata_this_mission,type_images=type_images,google_drive_upload=TRUE)

################### Function to fill the geoflow data frame with metadata #######################
get_session_metadata <- function(con_database, session_id, session_directory, google_drive_path, metadata_sessions,type_images="gopro",google_drive_upload){
  
  cat(paste0("Extracting metadata for mission: ", session_directory,"\n"))
  
  ################### Set directories #######################
  this_directory <- session_directory
  setwd(this_directory)
  sub_directories <- list.dirs(path=this_directory,full.names = TRUE,recursive = FALSE)
  number_sub_directories <-length(sub_directories)
  pattern = "*.JPG"
  files <- NULL
  Number_of_Pictures <- NULL
  directories <- paste(this_directory,"DCIM",sep="/")
  files <- list.files(path = directories, pattern = pattern,recursive = TRUE)
  Number_of_Pictures <- length(files)
  
  # first_picture_metadata <- read_exif(paste(directories[1], gsub(".*/","",files[1]),sep="/"))
  first_picture_metadata <- read_exif(paste(directories[1], files[1],sep="/"))
  # last_picture_metadata <- read_exif(paste(directories[length(directories)],gsub(".*/","",files[Number_of_Pictures]),sep="/"))
  last_picture_metadata <- read_exif(paste(directories[length(directories)],files[Number_of_Pictures],sep="/"))
  start_date<- as.POSIXct(first_picture_metadata$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
  end_date<- as.POSIXct(last_picture_metadata$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
  acquisition_time <- difftime(start_date, end_date, units="mins")
  
  #extract camera offset information
  if(!dir.exists("LABEL")){
    dir.create("LABEL")
    file_path = paste(this_directory,"LABEL","tag.txt",sep="/")
    line1 <- paste0(gsub(".*.DCIM","DCIM",first_picture_metadata$SourceFile)," => difftime(\"", start_date,"\", \"",start_date,"\", units=\"secs\")")
    writeLines(line1, file_path) 
  }
  con <- file(paste(this_directory,"LABEL","tag.txt",sep="/"),"r")
  first_line <- readLines(con,n=1)
  close(con)
  first_line <- sub('.*session', 'session', first_line)
  
  GPS_timestamp <- NULL
  Photo_GPS_timestamp <- NULL
  ################### Set directories ####################metadata_sessions=metadata_this_mission,type_images=type_images)###
  if(type_images=="drone"){
    pattern = "*.JPG"
    DCIM_directory <- "DCIM"
    date <- "2020-02-15"
    keywords="GENERAL:drone,coral reef_"
    photo_calibration_metadata <- read_exif(paste(this_directory, sub(' => .*', '', first_line),sep="/"))
    directories <- paste(this_directory,DCIM_directory,sep="/")

    # Photo_GPS_timestamp <- "2020-01-26 09:28:54"
    # GPS_timestamp <- "2020-01-26 09:28:54"
    # offset=0
    }else{
      activity=NULL
      if(grepl(pattern = "kite", x=session_id)){activity="Kite surfing"
      } else if(grepl(pattern = "surf", x=session_id)){activity="Surf"
      } else if(grepl(pattern = "addle", x=session_id)){activity="Paddle"
      } else if(grepl(pattern = "scuba", x=session_id)){activity="Snorkelling"}
      
      # keywords <- paste0("GENERAL: Mauritius, Seatizen, coral reef, underwater photos, deep learning, coral reef habitats, citizen sciences, ",activity,"_")
      # keywords_spatial <- paste0("GENERAL: Mauritius_")
      keywords <- paste0("GENERAL: Mauritius, Seatizen, coral reef, underwater photos, deep learning, coral reef habitats, citizen sciences, ",activity,"_")
      pattern = "*.JPG"
      DCIM_directory <- "DCIM"
      #' @juldebar => check
      date <- gsub("_","-",substr(session_id,9,18))
      photo_calibration_metadata <- read_exif(paste0(gsub(session_id,"",this_directory), sub(' => .*', '', first_line)))
      photo_directory <- sub('/G00.*', '',paste0(gsub(session_id,"",this_directory), sub(' => .*', '', first_line)))
      # saveRDS(photo_calibration_metadata, paste("toto",session_id,".RDS",sep=""))
      
      photo_calibration_metadata$DateTimeOriginal
      directories <- list.dirs(paste(this_directory,DCIM_directory,sep="/"), recursive = FALSE)
      directories <- directories[grepl("GOPRO", directories)]
      if (endsWith(photo_directory, "GOPRO") && 
          (grepl(pattern= "BEFORE",photo_directory)==TRUE ||
          grepl(pattern= "AFTER",photo_directory)==TRUE)){
      file.copy(photo_calibration_metadata$SourceFile, directories[1])
      }
      
    }
  
  ############# offset ################
  Photo_GPS_timestamp<- as.POSIXct(photo_calibration_metadata$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
  GPS_timestamp <- sub('.* => ', '', first_line)
  GPS_timestamp <- sub('secs\").*', 'secs\")', GPS_timestamp)
  # offset <- GPS_timestamp
  #############################
  
  ################### Set static metadata elements #######################
  title <- gsub("session 20","Session of the 20",gsub("_"," ",session_id))
  subject <- keywords
  description <- "abstract:"
  creator <- "owner:emmanuel.blondel1@gmail.com_\npointOfContact:sylvain.bonhommeau@ifremer.fr_\npointOfContact:julien.barde@ird.fr,wilfried.heintz@inra.fr"
  type <- "dataset"
  language <- "eng"
  # simplified_spatial_extent <-"LINESTRING (43.60036 -23.64388, 43.59685 -23.64484, 43.59815 -23.64696, 43.59785 -23.64713, 43.59655 -23.64499, 43.59624 -23.64515, 43.59754 -23.64728, 43.59724 -23.64744, 43.59594 -23.64531, 43.59562 -23.64546, 43.59692 -23.64759, 43.59663 -23.64775, 43.59533 -23.64563, 43.59502 -23.64577, 43.59631 -23.6479, 43.596 -23.64807, 43.59471 -23.64593, 43.59441 -23.64608, 43.5957 -23.64822, 43.59539 -23.64838, 43.59411 -23.64627, 43.59378 -23.6464, 43.59508 -23.64853, 43.59479 -23.64869, 43.59349 -23.64657, 43.59317 -23.64671, 43.59447 -23.64885, 43.59416 -23.64901, 43.59288 -23.64689, 43.59255 -23.64703, 43.59385 -23.64915, 43.59355 -23.64932, 43.59226 -23.6472, 43.59194 -23.64734, 43.59324 -23.64947, 43.59294 -23.64963, 43.59164 -23.6475, 43.59134 -23.64765, 43.59263 -23.64979, 43.59232 -23.64995, 43.59103 -23.64782, 43.59071 -23.64797, 43.59201 -23.6501)"
  simplified_spatial_extent <-"NULL"
  provenance <-"statement:This is some data quality statement providing information on the provenance"
  source <-"camera_"
  format <-gsub("*. ","",pattern)
  relation <- "Seatizen Web site@http://blabla_"
  gps_file <- "NULL"
  # spatial_extent <- NULL
  # temporal_extent <- NULL
  spatial_extent <- "NULL"
  temporal_extent <- "NULL"
  Number_of_Pictures <- Number_of_Pictures
  rights <-"use:terms1_"
  data_column <-""
  
  ################### Calculate dynamic metadata elements #######################
  ################### Number of Photos #######################

  if(Number_of_Pictures>0){
    df_countries=read.csv(paste0(code_directory,"CSV/countries.csv"))
    code_country=substr(str_split(string = session_id,pattern = "_")[[1]][2], 1, 3)
    this_country <- df_countries %>% filter(df_countries$alpha.3==code_country)
    
    description <- paste0(description,
                          "This dataset is made of ",Number_of_Pictures," pictures which have been collected in ",
                          this_country$name, ". The length of the data acquisition was : ", round(abs(acquisition_time))," minutes.")
    

    # https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.csv
    ############################################################
    ################### TEMPORAL COVERAGE ######################
    ############################################################
    cat("\n Metadata TEMPORAL COVERAGE \n")
    
    # geoflow entities data structure => 2007-03-01T13:00:00Z/2008-05-11T15:30:00Z
    # first_picture_metadata <- read_exif(paste(directories[1], gsub(".*/,",files[1]),sep="/"))
    # first_picture_metadata <- read_exif(paste(directories[1], gsub(".*/","",files[1]),sep="/"))
    # last_picture_metadata <- read_exif(paste(directories[length(directories)],gsub(".*/","",files[Number_of_Pictures]),sep="/"))
    # start_date<- as.POSIXct(first_picture_metadata$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
    # end_date<- as.POSIXct(last_picture_metadata$DateTimeOriginal, "%Y:%m:%d %H:%M:%OS", tz="UTC")
    # acquisition_time <- difftime(start_date, end_date, units="mins")
    start_date<-paste0(gsub(" ","T",start_date),"Z")
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
  cat("\n Metadata SPATIAL COVERAGE \n")
  
  file_type<-"TCX" #  "GPX"  "TCX" "RTK" "videos" "aerial"
  dataframe_gps_files <- return_dataframe_gps_files(this_directory,type=file_type)
  if(is.null(dataframe_gps_files)){
    cat("\n Search GPX instead of TCX \n")
    file_type<-"GPX"
    dataframe_gps_files <- return_dataframe_gps_files(this_directory,type=file_type)
  }
  if(is.null(dataframe_gps_files)){
    cat("\n Search GPKG instead of GPX \n")
    file_type<-"GPKG"
    dataframe_gps_files <- return_dataframe_gps_files(this_directory,type=file_type)
  }
  number_row <- nrow(dataframe_gps_files)
  
  if(number_row>0 && !is.null(number_row) ){
    cat("\n Build a spatial data frame \n")
    
    xmin <- NULL
    xmax <- NULL
    ymin <- NULL
    ymax <- NULL
    
    for (t in 1:number_row){
      
      gps_file <- paste(dataframe_gps_files$path[t],dataframe_gps_files$file_name[t],sep="/")
      ####################
      dataframe_gps_file <-NULL
      dataframe_gps_file <- return_dataframe_gps_file(con_database, 
                                                      wd=code_directory, 
                                                      gps_file=gps_file, 
                                                      type=file_type,
                                                      session_id=session_id,
                                                      load_in_database=FALSE
                                                      )
      #       head(dataframe_gps_file)
            xmin <- min(dataframe_gps_file$longitude)
            xmax <- max(dataframe_gps_file$longitude)
            ymin <- min(dataframe_gps_file$latitude)
            ymax <- max(dataframe_gps_file$latitude)
            spatial_extent <- paste("SRID=4326;POLYGON((",xmin,ymin,",",xmin,ymax,",",xmax,ymax,",",xmax,ymin,",",xmin,ymin,"))",sep=" ")
            ####################

            
            
      if(grepl(pattern = ".tcx",gps_file)){
        spatial_extent <- tcx_to_wkt(gps_file, dTolerance = 0.00005)
      } else if(grepl(pattern = ".gpx",gps_file)){
        spatial_extent <- gpx_to_wkt(gps_file, dTolerance = 0.00005)
      } else if(grepl(pattern = ".gpkg",gps_file)){
          cat("\n GPKG file ! ")
          spatial_data <- rgdal::readOGR(dsn = gps_file,stringsAsFactors = FALSE)
          spatial_data <- st_as_sf(spatial_data)
          spatial_extent <- spatial_data %>% st_coordinates() %>% st_linestring()  %>% st_as_text()
          
        }else{
          cat("\n no GPS file found !!")
          
          
        }
            # spatial_extent_geom <- sf::st_as_sfc(spatial_extent,wkt = "geom")
            spatial_extent_geom <- sf::st_as_sfc(paste0("SRID=4326;",spatial_extent))
            # spatial_extent_geom <- sf::st_as_sfc(spatial_extent)
            # spatial_extent_area <- sf::st_as_sfc(spatial_extent)
            # spatial_extent_length <- sf::st_as_sfc(spatial_extent)
            simplified_spatial_extent <- sf::st_as_sfc(spatial_extent) %>% st_simplify(dTolerance = 0.00005)  %>% st_as_text()
            bbox <- st_bbox(spatial_extent_geom)
            # bbox <- st_bbox(sf::st_as_sfc(spatial_extent) %>% st_simplify(dTolerance = 0.00005))
            # bb_area <- st_area(spatial_extent_geom)
            
      
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
      file_name <- paste0("photos_location_",session_id)
      
      ######################## store spatial data in a shape file
      # shp_filename <- paste0(sub('\\..*$', '', basename(gps_file)),"_",tolower(file_type))
      # # shp_filename <- file_name
      # if (!file.exists(paste0(shp_filename,".shp")) && type_images!="drone"){
      #   shape_file <- write_shp_from_csv(file_name=shp_filename)
      #   }
      # cat("\n Zip shape file \n")
      # zip(paste0(shp_filename,".zip"), c(paste0(shp_filename,".shp"),paste0(shp_filename,".shx"),paste0(shp_filename,".dbf"),paste0(shp_filename,".prj")))
      # 
      # gps_points <- st_as_sf(dataframe_gps_file, coords = c("longitude", "latitude"),crs = 4326)
      # bbox <- makebbox(ymax,xmax,ymin,xmin)
      # bbox <- makebbox(ymax+buffer,xmax+buffer,ymin-buffer,xmin-buffer)
      
      buffer <- 0.001
      
      # @juldebar => marche pas si petite surface ?
      bbox <- st_bbox(spatial_extent_geom)
      bbox <- makebbox(bbox$ymax+buffer,bbox$xmax+buffer,bbox$ymin-buffer,bbox$xmin-buffer)
      
      # https://cran.r-project.org/web/packages/pdftools/pdftools.pdf
      pdf_uri <- NULL
      jpeg_uri <-NULL
      pdf_spatial_extent <- paste0(session_id,".pdf")
      jpeg_spatial_extent <- paste0(session_id,".jpeg")
      if (!file.exists(pdf_spatial_extent)){
        # if (!file.exists(pdf_spatial_extent) && google_drive_upload==TRUE ){
          ######################## write a pdf and a jpeg file to get an overview of the spat https://cran.r-project.org/web/packages/rosm/rosm.pdf
        pdf(pdf_spatial_extent)
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
        
        #Add a layer with GPS points
        osm.points(longitude,latitude, col="yellow",pch=18, cex=0.5)
        dev.off()
        pdf_convert(pdf_spatial_extent, pages = NULL,format = "jpeg",dpi = 600,filenames=jpeg_spatial_extent)
        
        cat("\n Upload maps images on google drive \n")
        
      }
      
      sql_query <- paste0('SELECT * FROM "',session_id,'"')
      sql_query_filename <- paste0(session_id,'.sql')
      fileConn<-file(sql_query_filename)
      writeLines(sql_query, fileConn)
      close(fileConn)
      
      if(google_drive_upload==TRUE){
        check_pdf_uri<- drive_ls(path = google_drive_path, pattern = pdf_spatial_extent, recursive = FALSE)
        check_jpeg_uri <-drive_ls(path = google_drive_path, pattern = jpeg_spatial_extent, recursive = FALSE)
        check_shp_uri <-drive_ls(path = google_drive_path, pattern = paste0(gps_file,".zip"), recursive = FALSE)
        check_sql_uri <-drive_ls(path = google_drive_path, pattern = sql_query_filename, recursive = FALSE)
        
        if(nrow(check_pdf_uri)>0){
          pdf_uri <-paste0("https://drive.google.com/uc?id=",check_pdf_uri$id)
          }else{
          pdf_uri <-gsub("open\\?id","uc?id",paste0("https://drive.google.com/open?id=",upload_file_on_drive_repository(google_drive_path=google_drive_path,media=pdf_spatial_extent,file_name=pdf_spatial_extent,type="pdf")))
        }
        if(nrow(check_jpeg_uri)>0){
          jpeg_uri <-paste0("https://drive.google.com/uc?id=",check_jpeg_uri$id)
        }else{
          jpeg_uri <-gsub("open\\?id","uc?id",paste0("https://drive.google.com/open?id=",upload_file_on_drive_repository(google_drive_path=google_drive_path,media=jpeg_spatial_extent,file_name=jpeg_spatial_extent,type="jpeg")))
        }
        if(nrow(check_shp_uri)>0){
          shp_uri <-paste0("https://drive.google.com/uc?id=",check_shp_uri$id)
        }else{
          # shp_uri <-gsub("open\\?id","uc?id",paste0("https://drive.google.com/open?id=",upload_file_on_drive_repository(google_drive_path=google_drive_path,media=paste0(shp_filename,".zip"),file_name=paste0(shp_filename,".zip"),type="NULL")))
        }
        if(nrow(check_sql_uri)>0){
          sql_uri <-paste0("https://drive.google.com/uc?id=",check_sql_uri$id)
        }else{
          sql_uri <-gsub("open\\?id","uc?id",paste0("https://drive.google.com/open?id=",upload_file_on_drive_repository(DCMI_metadata_google_drive_path,media=sql_query_filename, file_name=sql_query_filename,type="text/rtf")))
        }
        
      }
      
      cat("\n Set Relation metadata element with google drive urls \n")
      relation <-paste0("thumbnail:",session_id,"[aperçu de la zone géographique]@",jpeg_uri)
      relation <-paste0(relation,"_\nhttp:map(pdf)@",pdf_uri)
      # data <-paste0("uploadType:dbview_\n:",pdf_uri)

      data_column <-paste0(
        'access:googledrive_\n',
        'source:',sql_query_filename,'_\n',
        'sourceType:dbquery_\n',
        'uploadSource:',session_id,'_\n',
        'uploadType:dbquery_\n',
        'sql:SELECT * FROM "',session_id,'"_\n',
        'featureType:reef_dbquery_\n',
        'upload:true_\n',
        'store:Reef_database_\n',
        'layername:',session_id,'_\n',
        'geometry:the_geom,Point_\n',
        'style:point_\n',
        'attribute:decimalLatitude[decimalLatitude],decimalLongitude[decimalLongitude],datasetID[datasetID],ImageSize[ImageSize],Model[Model],Make[Make]_\n',
        'variable:LightValue[LightValue]'
        )
  
      
      
      # data_column <-paste0('source:Postgis_\nsourceType:dbquery_\nuploadType:dbquery_\nsql:SELECT * FROM "',session_id,
      #               '"_\nsourceSql:SELECT * FROM "',session_id,
      #               '" LIMIT 1_\nlayername:',session_id,
      #               '_\nstyle:point_\nattribute:decimalLatitude[decimalLatitude],decimalLongitude[decimalLongitude],datasetID[datasetID],ImageSize[ImageSize],Model[Model],Make[Make]_\nvariable:LightValue[LightValue]')
      # 
      # data_column <-paste0("source:file:///tmp/dessin.pdf_\nsourceName:",session_id,"_\ntype:other_\nupload:true_")
      

      
      ######################## write a qgis project to visualize the shape file
      # qgs_template <- "/home/julien/Bureau/CODES/Deep_mapping/template/qgis_project_csv.qgs"
      # qgs_template <- "/home/julien/Bureau/CODES/Deep_mapping/template/qgis_project_shapefile_new.qgs"
      # write_qgis_project(session_id, qgs_template,shape_file,xmin,xmax,ymin,ymax)
      # get_session_metadata <- function(con_database, session_id, session_directory, google_drive_path, metadata_sessions,type_images="gopro",google_drive_upload){
        
      
      template_project="QGIS/template_project.qgs"
      pattern_root_path="/media/julien/SSD2TO/Deep_Mapping/drone/Madagascar/clean/2023/20230430_MDG-Nosy-Ve_UAV-01/20230430_MDG-Nosy-Ve_UAV-01_2/METADATA/"
      # pattern_root_path=gsub("//","/",paste0(session_directory,"/METADATA/"))
      pattern_root_path=gsub("//","/",pattern_root_path)
      pattern_session_id="20230430_MDG-Nosy-Ve_UAV-01_2"
      this_session_id=session_id
      pattern_relative_path= paste0(session_id,".gpkg")
      xmin_pattern="43.58705305555560017"
      ymin_pattern="-23.64932419444440015"
      xmax_pattern="43.60034630555559687"
      ymax_pattern="-23.64387211111110076"
      
      con <- file(paste0(code_directory,template_project),"r")
      lines <- readLines(con)
      close(con)
      # new_lines <- gsub(pattern_root_path,"./",lines)
      new_lines <- gsub(pattern_root_path,"",lines)
      new_lines <- gsub(pattern_session_id,this_session_id,new_lines)
      new_lines <- gsub(paste0(pattern_session_id,"_bf7f0265_413b_4f39_b0eb_360675cdfa89"),paste0(this_session_id,"_bf7f0265_413b_4f39_b0eb_360675cdfa89"),new_lines)
      
      gpkg_file <- sub("20230430_MDG-Nosy-Ve_UAV-01",substr(this_session_id, 1, (nchar(this_session_id)-2)),gsub(pattern_session_id,this_session_id,paste0(pattern_root_path,"metadata_",pattern_relative_path)))
      if(file.exists(gpkg_file)){
        # setwd(dirname(gpkg_file))
        spatial_data <- rgdal::readOGR(dsn = gpkg_file,stringsAsFactors = FALSE)
        spatial_data <- st_as_sf(spatial_data)
        bbox <- st_bbox(spatial_data)
      }else{
        spatial_extent <- paste("SRID=4326;POLYGON((",xmin,ymin,",",xmin,ymax,",",xmax,ymax,",",xmax,ymin,",",xmin,ymin,"))",sep=" ")
        spatial_extent_geom <- sf::st_as_sfc(spatial_extent)
        bbox <- st_bbox(spatial_extent_geom)
      }

      new_lines <- gsub(xmin_pattern,bbox$xmin,new_lines)
      new_lines <- gsub(xmax_pattern,bbox$xmax,new_lines)
      new_lines <- gsub(ymin_pattern,bbox$ymin,new_lines)
      new_lines <- gsub(ymax_pattern,bbox$ymax,new_lines)
      
      new_lines <- gsub("this_xmin",as.character(bbox$xmin-buffer),new_lines)
      new_lines <- gsub("this_xmax",as.character(bbox$xmax+buffer),new_lines)
      new_lines <- gsub("this_ymin",as.character(bbox$ymin-buffer),new_lines)
      new_lines <- gsub("this_ymax",as.character(bbox$ymax+buffer),new_lines)
      
      QGIS_project_filename <- paste0("../METADATA/",this_session_id,"_project.qgs")
      
      fileConn<-file(QGIS_project_filename)
      writeLines(new_lines, fileConn)
      close(fileConn)
      
      
      setwd(this_wd)
      
    }
  }else{
    cat("No GPS file when looking for TCX or GPX or RTK or GPKG files")
    cat(paste0("\n Pas de dossier'GPS' dans ", this_directory,"\n"))
    cat("Create GPS directory")
    if(!dir.exists(file.path(this_directory, "GPS"))){
      dir.create(file.path(this_directory, "GPS"))
    }
    
    # Check if RDS exist first ??
    if(!file.exists(paste0(session_directory,"/METADATA/exif/All_Exif_metadata_",session_id,".RDS"))){
      df <- extract_exif_metadata_in_csv(session_id,
                                         this_directory,
                                         template_df=read.csv(paste0(code_directory,"CSV/All_Exif_metadata_template.csv"),
                                                              colClasses=c(SourceFile="character",ExifToolVersion="numeric",FileName="character",Directory="character",
                                                                           FileSize="integer",FileModifyDate="character",FileAccessDate="character",FileInodeChangeDate="character",
                                                                           FilePermissions="integer",FileType="character",FileTypeExtension="character",MIMEType="character",
                                                                           ExifByteOrder="character",ImageDescription="character",Make="character",Orientation="integer",
                                                                           XResolution="integer",YResolution="integer",ResolutionUnit="integer",Software="character",ModifyDate="character",
                                                                           YCbCrPositioning="integer",ExposureTime="numeric",FNumber="numeric",ExposureProgram="integer",ISO="integer",
                                                                           ExifVersion="character",DateTimeOriginal="POSIXct",CreateDate="character",ComponentsConfiguration="character",
                                                                           CompressedBitsPerPixel="numeric",ShutterSpeedValue="numeric",ApertureValue="numeric",MaxApertureValue="numeric",
                                                                           SubjectDistance="integer",MeteringMode="integer",LightSource="integer",Flash="integer",FocalLength="integer",
                                                                           Warning="character",FlashpixVersion="character",ColorSpace="integer",ExifImageWidth="integer",ExifImageHeight="integer",
                                                                           InteropIndex="character",InteropVersion="character",ExposureIndex="character",SensingMethod="integer",FileSource="integer",
                                                                           SceneType="integer",CustomRendered="integer",ExposureMode="integer",DigitalZoomRatio="integer",FocalLengthIn35mmFormat="integer",
                                                                           SceneCaptureType="integer",GainControl="integer",Contrast="integer",Saturation="integer",DeviceSettingDescription="character",
                                                                           SubjectDistanceRange="integer",SerialNumber="character",GPSLatitudeRef="character",GPSLongitudeRef="character",GPSAltitudeRef="integer",
                                                                           GPSTimeStamp="character",GPSDateStamp="character",Compression="integer",ThumbnailOffset="integer",ThumbnailLength="integer",
                                                                           MPFVersion="character",NumberOfImages="integer",MPImageFlags="integer",MPImageFormat="integer",MPImageType="integer",
                                                                           MPImageLength="integer",MPImageStart="integer",DependentImage1EntryNumber="integer",DependentImage2EntryNumber="integer",
                                                                           ImageUIDList="character",TotalFrames="integer",DeviceName="character",FirmwareVersion="character",CameraSerialNumber="character",
                                                                           Model="character",AutoRotation="character",DigitalZoom="character",ProTune="character",WhiteBalance="character",Sharpness="character",
                                                                           ColorMode="character",AutoISOMax="integer",AutoISOMin="integer",ExposureCompensation="numeric",Rate="character",
                                                                           PhotoResolution="character",HDRSetting="character",ImageWidth="integer",ImageHeight="integer",EncodingProcess="integer",
                                                                           BitsPerSample="integer",ColorComponents="integer",YCbCrSubSampling="character",Aperture="numeric",GPSAltitude="numeric",
                                                                           GPSDateTime="POSIXct",GPSLatitude="numeric",GPSLongitude="numeric",GPSPosition="character",ImageSize="character",
                                                                           PreviewImage="character",Megapixels="integer",ScaleFactor35efl="integer",ShutterSpeed="numeric",ThumbnailImage="character",
                                                                           CircleOfConfusion="character",FOV="numeric",FocalLength35efl="integer",HyperfocalDistance="numeric",
                                                                           LightValue="numeric",session_id="character",session_photo_number="integer",relative_path="character",
                                                                           geometry_postgis="numeric",geometry_gps_correlate="numeric",geometry_native="numeric"),
                                                              stringsAsFactors = FALSE),
                                         mime_type=pattern,
                                         load_metadata_in_database=FALSE,
                                         time_zone="Indian/Mauritius")
    }else{
      # read existing exif metadata from RDS file
      df <- readRDS(paste0(session_directory,"/METADATA/exif/All_Exif_metadata_",session_id,".RDS"))
    }
    setwd(paste0(this_directory, "/GPS"))
    nrow_spatial_df_before <- nrow(df)
    spatial_df <- select(df, -c(ThumbnailImage,PreviewImage)) %>% filter(!is.na(GPSLatitude) & !is.null(GPSLatitude) & GPSLatitude!=0)
    nrow_spatial_df_after <- nrow(spatial_df)
    removed_images <- nrow_spatial_df_before-nrow_spatial_df_after
    cat(paste0("\n",removed_images, " images have been removed !!!! Either NA or Null values for GPS data \n"))
    
    plot_locations <- st_as_sf(spatial_df, coords = c("GPSLongitude", "GPSLatitude"),crs = 4326)
    st_write(plot_locations,paste0 (session_id,".gpkg"),delete_dsn = TRUE)
    
    spatial_extent <- plot_locations %>% st_coordinates() %>% st_linestring()  %>% st_as_text()
    spatial_extent_geom <- sf::st_as_sfc(spatial_extent)
    simplified_spatial_extent <- sf::st_as_sfc(spatial_extent) %>% st_simplify(dTolerance = 0.00005)  %>% st_as_text()
    mean_altitude <- mean(spatial_df$GPSAltitude)
    description <- paste0(description, ". The mean altidtude of this flight is : ", round(mean_altitude))
    # write_gpx_from_rds("test")
    # gps_file <- "No GPS file"
    # spatial_extent <- "No GPS file"
  }
###############################
  ################### CREATE DATAFRAME #######################
  ############################################################
  cat("\n Create metadata dataframe : \n")
  
  newRow <-NULL
  newRow <-data.frame(Identifier=session_id,#Identifier=paste0("id:",session_id),
                       Description=description,
                       Title=title,
                       Subject=subject,
                       Creator=creator,
                       Date=date,
                       Type="dataset",
                       SpatialCoverage=paste0("SRID=4326;",simplified_spatial_extent),
                       TemporalCoverage=temporal_extent,
                       Language=language,
                       Relation=relation,
                       Rights=rights,
                       Source=source,
                       Provenance=provenance,
                       Format=format,
                       Data=data_column,
                       # path=this_directory,
                       # GPS_timestamp=GPS_timestamp, # ??
                       # Photo_GPS_timestamp=Photo_GPS_timestamp, # ??
                       # geometry=spatial_extent_geom
                       # geometry=st_as_binary(spatial_extent_geom)
                       geometry=NA,
                       Number_of_Pictures=Number_of_Pictures,
                       Comment=NA,
                       Nb_photos_located=NA
  )
  
  metadata_sessions <- rbind(metadata_sessions,newRow)
  # metadata_sessions <- metadata_sessions[,c(1,2,3,16,17,4,18,19,7,8,9,10,11,12,5,6,13,14,15)]
  # metadata_sessions <- metadata_sessions[,c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17)]
  
  setwd(this_directory)
  return(metadata_sessions)
  #end function 
}
