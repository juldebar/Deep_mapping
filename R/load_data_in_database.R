# rm(list=ls())
codes_directory <-"~/Bureau/CODES/Deep_mapping/"
setwd(codes_directory)
source(paste0(codes_directory,"R/functions.R"))
source(paste0(codes_directory,"R/gpx_to_wkt.R"))
source(paste0(codes_directory,"R/credentials_databases.R"))
source(paste0(codes_directory,"R/get_session_metadata.R"))
#attention pas de slash à la fin du path
images_directory <- "/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/Drone_images/2019_10_11_Le_Morne"
type_images <- "drone"
images_directory <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/good/database"
type_images <- "gopro"

# images_directory <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/good/validated"
missions <- list.dirs(path = images_directory, full.names = TRUE, recursive = FALSE)

con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)
create_database(con_Reef_database, codes_directory)
# set_time_zone <- dbGetQuery(con_Reef_database, "SET timezone = 'UTC+04:00'")

metadata_missions <- data.frame(
  Identifier=character(),
  Description=character(),
  Title=character(),
  Subject=character(),
  Creator=character(),
  Date=character(),
  Type=character(),
  SpatialCoverage=character(),
  TemporalCoverage=character(),
  Language=character(),
  Relation=character(),
  Rights=character(),  
  Source=character(),  
  Provenance=character(),
  Format=character(),
  Data=character(),
  path=character(),
  gps_file_name=character(),
  Number_of_Pictures=integer(),
  GPS_timestamp=character(),
  Photo_GPS_timestamp=character(),
  geometry=character()
)

google_drive_path <- drive_get(id="1gUOhjNk0Ydv8PZXrRT2KQ1NE6iVy-unR")
google_drive_file_url <- paste0("https://drive.google.com/open?id=",google_drive_path$id)

for(m in missions){
  cat(paste0(m,"\n"))
  setwd(m)
  nb_photos_located <- load_data_in_database(con_database=con_Reef_database, mission_directory=m)
  # metadata_sessions$nb_photos_located <- nb_photos_located
  metadata_missions <- get_session_metadata(session_directory=m, google_drive_path,metadata_missions,type_images=type_images)
}
names(metadata_missions)
head(metadata_missions)
metadata_missions$geometry
load_DCMI_metadata_in_database(con_Reef_database, codes_directory, metadata_missions,create_table=TRUE)

setwd(images_directory)
local_file_path <-"metadata_missions.csv"
file_name <-"metadata_missions.csv"
write.csv(metadata_missions,file = file_name,row.names = F)
nrow(metadata_missions)
sum(metadata_missions$Number_of_Pictures)


dbDisconnect(con_Reef_database)

########################################################################################################################
################### Run geoflow #######################
########################################################################################################################
google_drive_path <- drive_get(id="1gUOhjNk0Ydv8PZXrRT2KQ1NE6iVy-unR")
google_drive_path <- drive_get(id="0B0FxQQrHqkh0NnZ0elY5S0tHUkJxZWNLQlhuQnNGOE15YVlB")
# drive_download("Deep_mappping_worflow.json")
# setwd(paste0(codes_directory,"R/geoflow"))
setwd(images_directory)
require(geoflow)
configuration_file <- "/home/juldebar/Bureau/CODES/Deep_mapping/R/Deep_mappping_worflow.json"
# executeWorkflow(file = "Deep_mappping_worflow.json")
initWorkflow(file = configuration_file)
executeWorkflow(file = configuration_file)


load_data_in_database <- function(con_database, mission_directory){
  
  # SET DIRECTORIES & LOAD SOURCES & CONNECT DATABASE
  dataset_time_zone <- "Indian/Mauritius"
  

  session_id <- gsub(" ","_",gsub(paste0(dirname(mission_directory),"/"),"",mission_directory))
  
  # SET DIRECTORIES & LOAD SOURCES & CONNECT DATABASE
  if(type_images=="drone"){
    mime_type = "*.jpg"
    prefix_mission = "Mission"
    images_dir = "./data"
    gps_dir = "./"
    file_type<-"GPX"
    offset <- 0
    
    }else if(type_images=="gopro"){
      mime_type = "*.JPG"
      prefix_mission = "session_"
      gps_dir = "GPS"
      images_dir = "./DCIM"
      file_type<-"TCX" #  "GPX"  "TCX" "RTK"
      
      # Calculate offset between timestamps of the camera and GPS
      con <- file(paste0(mission_directory,"/LABEL/tag.txt"),"r")
      first_line <- readLines(con,n=1)
      close(con)
      offset <- eval(parse(text = sub(".*=> ","",first_line)))
      }
  

  
  # EXTRACT exif metadata elements & store them in a CSV file & LOAD THEM INTO POSTGRES DATABASE
  # extract exif metadata and store it into a CSV or RDS file
  # if(!file.exists(paste0(mission_directory,"/METADATA/exif/All_Exif_metadata_",session_id,".RDS"))){
  if(!file.exists(paste0(mission_directory,"/METADATA/exif/All_Exif_metadata_",session_id,".RDS"))){
      template_df <- read.csv(paste0(codes_directory,"CSV/All_Exif_metadata_template.csv"),stringsAsFactors = FALSE)
      head_metadata_pictures <- extract_exif_metadata_in_csv(images_directory = mission_directory, template_df, mime_type,load_metadata_in_database=FALSE,time_zone=dataset_time_zone)
  }
  # read the exif metadata from RDS file
  exif_core_metadata_elements <- list.files(path = paste0(mission_directory,"/METADATA/exif"), pattern = paste0("All_Exif_metadata_",session_id,".RDS"))
  photos_metadata <-NULL
  metadata_pictures <-NULL
  for (f in exif_core_metadata_elements){
    if(grepl(".RDS",f)){
      photos_metadata <- readRDS(paste0(mission_directory,"/METADATA/exif/",f))
      if(!is.null(photos_metadata)){
        # add condition exists before susbet ?
        metadata_pictures <- select(photos_metadata,
                                    session_id,
                                    session_photo_number,
                                    relative_path,
                                    FileName,
                                    GPSLatitude,
                                    GPSLongitude,
                                    GPSDateTime,
                                    DateTimeOriginal,
                                    # Raw_Time_Julien,
                                    LightValue,
                                    ImageSize,
                                    Model,
                                    geometry_postgis,
                                    geometry_gps_correlate,
                                    geometry_native,
                                    ThumbnailImage,
                                    PreviewImage                             
                                    
        )
        # name_file_csv<-paste("Core_Exif_metadata_",session_id,".csv",sep="")
        # saveRDS(metadata_pictures, paste("Core_Exif_metadata_",session_id,".RDS",sep=""))
        # load the exif metadata in the SQL database
        load_exif_metadata_in_database(con_Reef_database, codes_directory, metadata_pictures, create_table=FALSE)
        #  Check that the SQL database was properly loaded
        check_database <- dbGetQuery(con_Reef_database, paste0("SELECT * FROM photos_exif_core_metadata WHERE session_id='",session_id,"' LIMIT 10"))
        check_database
        
        # Check offset from pictures with embedded GPS in the camera
        offset_db <-NULL
        sql_query <- paste0('select ("GPSDateTime" - "DateTimeOriginal") AS offset, * FROM photos_exif_core_metadata WHERE "GPSDateTime" IS NOT NULL LIMIT 10')
        # check_offset_from_pictures <- dbGetQuery(con_Reef_database,sql_query)
        # check_offset_from_pictures
        
        # Check first if GPS data is embedded in the camera (model not gopro session 5)
        # offset_db <-difftime(check_offset_from_pictures$DateTimeOriginal,check_offset_from_pictures$GPSDateTime,units="secs")
        # offset_db
        
        }else{
        cat("no pictures in this session ! \n")
      }
      
      }
  }


  
  #EXTRACT GPS TRACKS DATA AND LOAD THEM INTO POSTGRES DATABASE
  # define expected mime type for the search
  # check the number of GPS files for the session (sometimes more than one: battery issue..)
  # Use function "dataframe_gps_files" to list all gps files
  setwd(m)
  
  if(!dir.exists(file.path(mission_directory, "GPS"))){
    cat("Create GPS directory")
    dir.create(file.path(mission_directory, "GPS"))
  }
  dataframe_gps_files <- NULL
  dataframe_gps_files <- data.frame(session=character(), path=character(), file_name=character())
  
  if(type_images=="drone"){
    gps_files <- list.files(pattern = "\\.gpx$",ignore.case=TRUE)
    file.copy(gps_files, "./GPS")
    newRow <- data.frame(session=session_id,path=m,file_name=gps_files)
    dataframe_gps_files <- rbind(dataframe_gps_files,newRow)
    }else{
    dataframe_gps_files <- return_dataframe_gps_files(mission_directory,type=file_type)
    number_row<-nrow(dataframe_gps_files)
    if(is.null(number_row)){
      file_type<-"GPX"
      dataframe_gps_files <- return_dataframe_gps_files(mission_directory,type=file_type)
    }
  }
  number_row<-nrow(dataframe_gps_files)
  
  # if more than one (sometimes for some reasons, the same session has multiple GPS tracks) => iterate => difference between end point and start point > frequency
  if(!is.null(number_row)){
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
      # plot_tcx(gps_file,mission_directory)
      cat("GPS tracks loaded in the database")
    }
  }else(cat("No GPS file when looking for TCX or GPX files => RTK ??"))
  
  # INFER LOCATION OF PHOTOS FROM GPS TRACKS TIMESTAMP
  photo_location <- infer_photo_location_from_gps_tracks(con_Reef_database, mission_directory, codes_directory,session_id , offset=offset,create_view=TRUE)
  head(photo_location$the_geom,n = 50)
  paste0("For a total of ",nrow(photos_metadata), " photos")
  paste0(nrow(photo_location), " photos have been located from GPS tracks")
  ratio = nrow(photo_location) / nrow(photos_metadata)
  ratio
  nrow(dataframe_gps_file)
  
  return(nrow(photo_location))
}

