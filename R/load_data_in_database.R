# rm(list=ls())
pacman::p_load(remotes,geoflow,googledrive, exifr, RPostgreSQL, rgdal, data.table,dplyr,trackeR,lubridate)

codes_directory <-"~/Bureau/CODES/Deep_mapping/"
codes_github_repository <-"https://raw.githubusercontent.com/juldebar/Deep_mapping/master/"
images_directory <- "/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/Deep_Mapping/new"

setwd(codes_directory)
configuration_file <- paste0(codes_directory,"Deep_mappping_worflow.json")
source(paste0(codes_github_repository,"R/functions.R"))
source(paste0(codes_github_repository,"R/gpx_to_wkt.R"))
source(paste0(codes_directory,"R/credentials_databases.R"))
source(paste0(codes_github_repository,"R/get_session_metadata.R"))
#warning: no slash at the end of the path
# set_time_zone <- dbGetQuery(con_Reef_database, "SET timezone = 'UTC+04:00'")

cat("Connect the database\n")
con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)
cat("Replace the database\n")
create_database(con_Reef_database, codes_github_repository)

#if multiple missions, list sub-repositories
missions <- list.dirs(path = images_directory, full.names = TRUE, recursive = FALSE)
#if only one mission, indicate the specirfic sub-repository
# missions <- paste0(images_directory,"/","session_2019_10_12_kite_Le_Morne")

#specify which google drive folder should be used to store files
google_drive_path <- drive_get(id="1tZrN_zKxhc6Q0ysUp8XEbTnID6HCV13K")
google_drive_file_url <- paste0("https://drive.google.com/open?id=",google_drive_path$id)

#iterate on all missions to load the database with data (Dublin Core metadata, GPS data, exif metadata)
c=0
for(m in missions){
  c <-c+1
  cat(c)
  metadata_this_mission <- NULL
  if(grepl(pattern = "drone",m)){
    type_images <- "drone"
    platform <- "drone"
    missions_drone <- m
    missions_drone <- list.dirs(path = m, full.names = TRUE, recursive = FALSE)
    for(md in missions_drone){
      setwd(md)
      cat(paste0("Processing mission: ", md,"\n"))
      metadata_this_mission <- get_session_metadata(con_database=con_Reef_database, session_directory=md, google_drive_path,metadata_sessions=metadata_this_mission,type_images=type_images)
      load_DCMI_metadata_in_database(con_Reef_database, codes_directory, metadata_this_mission,create_table=FALSE)
      ratio <- load_data_in_database(con_database=con_Reef_database, mission_directory=md, platform)
      }
    }else{
      setwd(m)
      type_images <- "gopro"
      platform <- "kite"
      cat(paste0("Processing mission: ", m,"\n"))
      cat(paste0("Extracting dynamic metadata: ", m,"\n"))
      metadata_this_mission <- get_session_metadata(con_database=con_Reef_database, session_directory=m, google_drive_path,metadata_sessions=metadata_this_mission,type_images=type_images)
      cat(paste0("Loading dynamic metadata in the database: ", m,"\n"))
      load_DCMI_metadata_in_database(con_Reef_database, codes_directory, metadata_this_mission,create_table=FALSE)
      cat(paste0("Extract and load exif metadata in the database: ", m,"\n"))
      ratio <- load_data_in_database(con_database=con_Reef_database, mission_directory=m,platform)
      cat(paste0("Load tags of photos in the database: ", m,"\n"))
      url <-paste0("https://docs.google.com/spreadsheets/d/",tags_file_google_drive_path$id)
      tags_file_google_drive <- as.data.frame(gsheet::gsheet2tbl(url))
      query <-update_annotations_in_database(con_database=con_Reef_database, images_tags_and_labels=tags_file_google_drive)
    }
  metadata_this_mission$Comment <- paste0("Ratio d'images géoréférencées: ",ratio[1]/ratio[2], "(images géoréférencées: ", ratio[1]," pour un total d'images de : ", ratio[2],")")
  metadata_this_mission$Nb_photos_located <- ratio[1]
  if(c==1){
    metadata_missions <- metadata_this_mission
  }else{
    metadata_missions <- rbind(metadata_missions,metadata_this_mission)
    }
  
}


cat(paste0("Ratio of geolocated images / Total number of images : ",ratio[1]/ratio[2]))

#write metadata table
colnames(metadata_this_mission)
setwd(images_directory)
file_name <-"metadata_missions.csv"
write.csv(metadata_missions,file = file_name,row.names = F)
DCMI_metadata_google_drive_path <- drive_get(id="12anx6McwA6xiZeswfF8Y9sGuQSnohWZsUNIhc1fFjnw")
googledrive::drive_update(file=DCMI_metadata_google_drive_path,name=file_name,media=file_name)


#Number of mission processed in the iteration
nrow(metadata_missions)
#Sum of images processed in the iteration
sum(metadata_missions$Number_of_Pictures)

#Merge all tags from different sessions
images_directory <- "/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/Deep_Mapping/new"
df <- return_dataframe_tag_txt(images_directory)
head(df)

setwd("/tmp")
files <- list.files(pattern = "*ter.csv")
all_files <- NULL
all_files <- Reduce(rbind, lapply(files, read.csv))
all_files$old_tag <-all_files$tag
head(all_files)
file_name <-"all.csv"
write.table(x = all_files,file = file_name, sep=",",row.names = FALSE)
newdf <- read.csv("all.csv",sep = ",")
newdf$photo_name=paste0(newdf$name_session,"_",newdf$file_name)
head(newdf)
system(command = "awk 'FNR==1 && NR!=1{next;}{print}' *ter.csv  > combined.csv")
tags_folder_google_drive_path <- drive_get(id="1U6I6tgAqKRDgurb7gnQGV8Q5_i_jJSB4")
tags_file_google_drive_path <- drive_get(id="1eFJq003Z3JayIHtgupYfM01qV2IVT3VuBeYt6a0OKdM")
googledrive::drive_update(file=tags_file_google_drive_path,name=file_name,media=file_name)



#Load annotation table
# 1qT9j398DhTmvBvBd0FZvoesy3kMkOta96YZQVhT5Tjw
list_images_with_tags_and_labels <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1eFJq003Z3JayIHtgupYfM01qV2IVT3VuBeYt6a0OKdM/edit?usp=sharing"))
# list_images_with_tags_and_labels <- as.data.frame(gsheet::gsheet2tbl("https://drive.google.com/open?id=1TkX5P7pr5MEvxr7J78tCMKrSGzqUSG-FXicod9yLCEc"))
cat("Update annotations in the database with the content of this google sheet \n")
# update_annotations_in_database(con_Reef_database, codes_directory, list_images_with_tags_and_labels, create_table=FALSE)

#Disconnect database
dbDisconnect(con_Reef_database)

########################################################################################################################
################### Run geoflow to load Geonetwork and Geoserver #######################
########################################################################################################################
# google_drive_path <- drive_get(id="0B0FxQQrHqkh0NnZ0elY5S0tHUkJxZWNLQlhuQnNGOE15YVlB")
google_drive_path <- drive_get(id="1gUOhjNk0Ydv8PZXrRT2KQ1NE6iVy-unR")

# drive_download("Deep_mappping_worflow.json")
setwd(codes_directory)
configuration_file <- "Deep_mappping_worflow.json"
# initWorkflow(file = configuration_file)
executeWorkflow(file = configuration_file)
upload_file_on_drive_repository(google_drive_path,configuration_file)
