# rm(list=ls())
require(geoflow)
# configuration_file <- "/home/juldebar/Bureau/CODES/Deep_mapping/R/Deep_mappping_worflow.json"
configuration_file <- "/home/juldebar/Bureau/CODES/Deep_mapping/Deep_mappping_worflow.json"

codes_directory <-"~/Bureau/CODES/Deep_mapping/"
setwd(codes_directory)
source(paste0(codes_directory,"R/functions.R"))
source(paste0(codes_directory,"R/gpx_to_wkt.R"))
source(paste0(codes_directory,"R/credentials_databases.R"))
source(paste0(codes_directory,"R/get_session_metadata.R"))
#attention pas de slash à la fin du path
images_directory <- "/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/Drone_images/2019_10_11_Le_Morne"
images_directory <- "/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/Deep_Mapping/test/database"
# images_directory <- "/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/Deep_Mapping/test/database/Mission1"
# images_directory <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/good/database"
# images_directory <- "/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/Deep_Mapping/test/database"
images_directory <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/good"

con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)
create_database(con_Reef_database, codes_directory)

# images_directory <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/good/validated"
missions <- list.dirs(path = images_directory, full.names = TRUE, recursive = FALSE)
missions <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/good/validated/session_2019_05_11_kite_le_Morne_Lapointe"

# set_time_zone <- dbGetQuery(con_Reef_database, "SET timezone = 'UTC+04:00'")
metadata_missions <- NULL
# metadata_missions <- data.frame(
#   Identifier=character(),
#   Description=character(),
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
#   Format=character(),
#   Data=character(),
#   path=character(),
#   gps_file_name=character(),
#   Number_of_Pictures=integer(),
#   GPS_timestamp=character(),
#   Photo_GPS_timestamp=character(),
#   geometry=character()
# )

google_drive_path <- drive_get(id="1gUOhjNk0Ydv8PZXrRT2KQ1NE6iVy-unR")
google_drive_file_url <- paste0("https://drive.google.com/open?id=",google_drive_path$id)

c=0
for(m in missions){
  c <-c+1
  metadata_missions <- NULL
  if(grepl(pattern = "drone",m)){
    type_images <- "drone"
    platform <- "drone"
    missions_drone <- m
    missions_drone <- list.dirs(path = m, full.names = TRUE, recursive = FALSE)
    for(md in missions_drone){
      setwd(md)
      metadata_missions <- NULL
      cat(paste0("Processing mission: ", md,"\n"))
      metadata_missions <- get_session_metadata(con_database=con_Reef_database, session_directory=md, google_drive_path,metadata_missions,type_images=type_images)
      load_DCMI_metadata_in_database(con_Reef_database, codes_directory, metadata_missions,create_table=FALSE)
      ratio <- load_data_in_database(con_database=con_Reef_database, mission_directory=md, platform)
      }
    }else{
      setwd(m)
      type_images <- "gopro"
      platform <- "kite"
      cat(paste0("Processing mission: ", m,"\n"))
      metadata_missions <- get_session_metadata(con_database=con_Reef_database, session_directory=m, google_drive_path,metadata_missions,type_images=type_images)
      load_DCMI_metadata_in_database(con_Reef_database, codes_directory, metadata_missions,create_table=FALSE)
      ratio <- load_data_in_database(con_database=con_Reef_database, mission_directory=m,platform)
      metadata_missions$Comment <- paste0("Ratio d'images géoréférencées: ",ratio[1]/ratio[2], "(images géoréférencées: ", ratio[1]," pour un total d'images de : ", ratio[2],")")
      }
  # metadata_missions$nb_photos_located[c] <- nb_photos_located
}
cat(paste0("Ratio d'images géoréférencées: ",ratio[1]/ratio[2]))

#Load metadata table
names(metadata_missions)
setwd(images_directory)
local_file_path <-"metadata_missions.csv"
file_name <-"metadata_missions.csv"
write.csv(metadata_missions,file = file_name,row.names = F)
nrow(metadata_missions)
sum(metadata_missions$Number_of_Pictures)

#Load annotation table
list_images_with_tags_and_labels <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/14XiNE6gvXjWZg9YAQZ-OWvdgYBDL6knoLD86ZRvx_jw/edit?usp=sharing"))
# list_images_with_tags_and_labels <- as.data.frame(gsheet::gsheet2tbl("https://drive.google.com/open?id=1TkX5P7pr5MEvxr7J78tCMKrSGzqUSG-FXicod9yLCEc"))
update_annotations_in_database(con_Reef_database, codes_directory, list_images_with_tags_and_labels, create_table=FALSE)

#Disconnect database
dbDisconnect(con_Reef_database)

########################################################################################################################
################### Run geoflow to load Geonetwork and Geoserver #######################
########################################################################################################################
google_drive_path <- drive_get(id="0B0FxQQrHqkh0NnZ0elY5S0tHUkJxZWNLQlhuQnNGOE15YVlB")
google_drive_path <- drive_get(id="1gUOhjNk0Ydv8PZXrRT2KQ1NE6iVy-unR")

# drive_download("Deep_mappping_worflow.json")
setwd(codes_directory)
configuration_file <- "Deep_mappping_worflow.json"
# initWorkflow(file = configuration_file)
executeWorkflow(file = configuration_file)
upload_file_on_drive_repository(google_drive_path,configuration_file)
