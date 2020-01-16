# rm(list=ls())
codes_directory <-"~/Bureau/CODES/Deep_mapping/"
setwd(codes_directory)
source(paste0(codes_directory,"R/functions.R"))
source(paste0(codes_directory,"R/gpx_to_wkt.R"))
source(paste0(codes_directory,"R/credentials_databases.R"))
source(paste0(codes_directory,"R/get_session_metadata.R"))
images_directory <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/good/database"
# images_directory <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/good/validated"
sessions <- list.dirs(path = images_directory, full.names = TRUE, recursive = FALSE)

con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)
create_database(con_Reef_database, codes_directory)
# set_time_zone <- dbGetQuery(con_Reef_database, "SET timezone = 'UTC+04:00'")

metadata_sessions <- data.frame(
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

for(s in sessions){
  cat(paste0(s,"\n"))
  setwd(s)
  load_data_in_database(con_database=con_Reef_database, images_directory=s)
  metadata_sessions <- get_session_metadata(session_directory=s, google_drive_path,metadata_sessions)
}
names(metadata_sessions)
head(metadata_sessions)
metadata_sessions$geometry
load_DCMI_metadata_in_database(con_Reef_database, codes_directory, metadata_sessions,create_table=TRUE)

setwd(images_directory)
local_file_path <-"metadata_sessions.csv"
file_name <-"metadata_sessions.csv"
write.csv(metadata_sessions,file = file_name,row.names = F)
nrow(metadata_sessions)
sum(metadata_sessions$Number_of_Pictures)


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


load_data_in_database <- function(con_database, images_directory){
  
  # SET DIRECTORIES & LOAD SOURCES & CONNECT DATABASE
  dataset_time_zone <- "Indian/Mauritius"
  session_id <- gsub(paste0(dirname(images_directory),"/"),"",images_directory)
  
  # Calculate offset between timestamps of the camera and GPS
  con <- file(paste0(images_directory,"/LABEL/tag.txt"),"r")
  first_line <- readLines(con,n=1)
  close(con)
  offset <- eval(parse(text = sub(".*=> ","",first_line)))
  
  # EXTRACT exif metadata elements & store them in a CSV file & LOAD THEM INTO POSTGRES DATABASE
  # extract exif metadata and store it into a CSV or RDS file
  if(!file.exists(paste0(images_directory,"/METADATA/exif/All_Exif_metadata_",session_id,".RDS"))){
    template_df <- read.csv(paste0(codes_directory,"CSV/All_Exif_metadata_template.csv"),stringsAsFactors = FALSE)
    last_metadata_pictures <- extract_exif_metadata_in_csv(images_directory=images_directory, template_df, load_metadata_in_database=FALSE,time_zone=dataset_time_zone)
  }
  # read the exif metadata from RDS file
  exif_core_metadata_elements <- list.files(path = paste0(images_directory,"/METADATA/exif"), pattern = "Core_Exif_metadata_")
  photos_metadata <-NULL
  for (f in exif_core_metadata_elements){
    if(grepl(".RDS",f)){photos_metadata <- readRDS(paste0(images_directory,"/METADATA/exif/",f))}
  }
  # load the exif metadata in the SQL database
  load_exif_metadata_in_database(con_Reef_database, codes_directory, photos_metadata, create_table=FALSE)
  #  Check that the SQL database was properly loaded
  check_database <- dbGetQuery(con_Reef_database, paste0("SELECT * FROM photos_exif_core_metadata WHERE session_id='",session_id,"' LIMIT 10"))
  check_database
  
  # Check offset from pictures with embedded GPS in the camera
  sql_query <- paste0('select ("GPSDateTime" - "DateTimeOriginal") AS offset, * FROM photos_exif_core_metadata WHERE "GPSDateTime" IS NOT NULL LIMIT 10')
  offset_db <-NULL
  check_offset_from_pictures <- dbGetQuery(con_Reef_database,sql_query)
  offset_db <-difftime(check_offset_from_pictures$DateTimeOriginal,check_offset_from_pictures$GPSDateTime,units="secs")
  offset_db
  
  #EXTRACT GPS TRACKS DATA AND LOAD THEM INTO POSTGRES DATABASE
  # define expected mime type for the search
  file_type<-"TCX" #  "GPX"  "TCX" "RTK"
  # check the number of GPS files for the session (sometimes more than one: battery issue..)
  # Use function "dataframe_gps_files" to list all gps files
  dataframe_gps_files <- return_dataframe_gps_files(images_directory,type=file_type)
  number_row<-nrow(dataframe_gps_files)
  if(is.null(number_row)){
    file_type<-"GPX"
    dataframe_gps_files <- return_dataframe_gps_files(images_directory,type=file_type)
    number_row<-nrow(dataframe_gps_files)
  }
  
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
      # plot_tcx(gps_file,images_directory)
    }
  }else(cat("No GPS file when looking for TCX or GPX files => RTK ??"))
  
  # INFER LOCATION OF PHOTOS FROM GPS TRACKS TIMESTAMP
  photo_location <- infer_photo_location_from_gps_tracks(con_Reef_database, images_directory, codes_directory,session_id , offset=offset,create_view=TRUE)
  head(photo_location$the_geom,n = 50)
  paste0("For a total of ",nrow(photos_metadata), " photos")
  paste0(nrow(photo_location), " photos have been located from GPS tracks")
  ratio = nrow(photo_location) / nrow(photos_metadata)
  ratio
  nrow(dataframe_gps_file)
  
}

