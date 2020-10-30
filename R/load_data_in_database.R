rm(list=ls())
codes_directory <-"~/Desktop/CODES/Deep_mapping/"
source(paste0(codes_directory,"R/credentials_databases.R"))
setwd(codes_directory)

configuration_file <- paste0(codes_directory,"Deep_mappping_worflow.json")
codes_github_repository=codes_directory
source(paste0(codes_github_repository,"R/functions.R"))
source(paste0(codes_github_repository,"R/gpx_to_wkt.R"))
source(paste0(codes_github_repository,"R/get_session_metadata.R"))
#warning: no slash at the end of the path
# set_time_zone <- dbGetQuery(con_Reef_database, "SET timezone = 'UTC+04:00'")

cat("Connect the database\n")
con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)
cat("Replace the database\n")
create_database(con_Reef_database, codes_github_repository)

#if multiple missions, list sub-repositories
missions <- list.dirs(path = images_directory, full.names = TRUE, recursive = FALSE)
#if only one mission, indicate the specific sub-repository
# missions <- paste0(images_directory,"/","session_2019_10_12_kite_Le_Morne")
# missions <- "/media/julien/3362-6161/saved/session_2019_09_12_kite_Le_Morne"


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
      ratio <- load_data_in_database(con_database=con_Reef_database, codes_directory, mission_directory=md, platform)
      }
    }else{
      cat(paste0("Processing mission: ", m,"\n"))
      setwd(m)
      session_id <- gsub(paste0(dirname(m),"/"),"",m)
      type_images <- "gopro"
      platform <- "kite"
      cat(paste0("Extracting dynamic metadata: ", m,"\n"))
      metadata_this_mission <- get_session_metadata(con_database=con_Reef_database, session_directory=m, google_drive_path,metadata_sessions=metadata_this_mission,type_images=type_images)
      cat(paste0("Upload metadata on google drive: ", m,"\n"))
      file_name <- paste0(session_id,"_DCMI_metadata.csv")
      write.csv(metadata_this_mission,file = file_name,row.names = F)
      # googledrive::drive_update(file=DCMI_metadata_google_drive_path,name=file_name,media=file_name)
      gsheet_id <- upload_file_on_drive_repository(DCMI_metadata_google_drive_path,media=file_name, file_name=file_name,type="spreadsheet")
      
      cat(paste0("Loading dynamic metadata in the database: ", m,"\n"))
      load_DCMI_metadata_in_database(con_Reef_database, codes_directory, metadata_this_mission[,c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17)],create_table=FALSE)
      cat(paste0("Extract and load exif metadata in the database: ", m,"\n"))
      ratio <- load_data_in_database(con_database=con_Reef_database, codes_directory=codes_directory, mission_directory=m,platform)
      # lapply(ratio,class)
      cat(paste0("Load tags of photos in the database: ", m,"\n"))
      tags_as_csv <- return_dataframe_tag_txt(m)
      file_name <- paste0(session_id,"_tag.csv")
      gsheet_id <- upload_file_on_drive_repository(tags_folder_google_drive_path,media=tags_as_csv, file_name,type="spreadsheet")
      url <-paste0("https://docs.google.com/spreadsheets/d/",gsheet_id)
      tags_file_google_drive <- as.data.frame(gsheet::gsheet2tbl(url))
      # query <-update_annotations_in_database(con_database=con_Reef_database, images_tags_and_labels=tags_file_google_drive)
    }
  metadata_this_mission$Comment <- paste0("Ratio d'images géoréférencées: ",ratio[1]/ratio[2], "(images géoréférencées: ", ratio[1]," pour un total d'images de : ", ratio[2],")")
  metadata_this_mission$Nb_photos_located <- ratio[1]
  if(c==1){
    metadata_missions <- metadata_this_mission
  }else{
    metadata_missions <- rbind(metadata_missions,metadata_this_mission)
    }
}

#write metadata table
setwd(images_directory)
file_name <-"metadata_all_sessions.csv"
write.csv(metadata_missions,file = file_name,row.names = F)
googledrive::drive_update(file=DCMI_metadata_google_drive_path,name=file_name,media=file_name)
upload_file_on_drive_repository(google_drive_path=google_drive_path,media=pdf_spatial_extent,file_name=pdf_spatial_extent,type=NULL)
ratio
cat(paste0("Ratio of geolocated images / Total number of images : ",ratio[1]/ratio[2]))

#Number of mission processed in the iteration
nrow(metadata_missions)
#Sum of images processed in the iteration
sum(metadata_missions$Number_of_Pictures)

#Merge all tags from different sessions
all_tags_as_csv <- return_dataframe_tag_txt(images_directory)
all_tags_as_csv <- return_dataframe_tag_txt("/media/julien/Deep_Mapping_bac/data_deep_mapping/2019/good/checked")
all_tags_as_csv <- return_dataframe_tag_txt("/media/julien/Deep_Mapping_bac/data_deep_mapping/2018/GOOD")

file_name <- paste0("all_sessions_tags.csv")
gsheet_id <- upload_file_on_drive_repository(tags_folder_google_drive_path,media=all_tags_as_csv, file_name,type="spreadsheet")
url <-paste0("https://docs.google.com/spreadsheets/d/",gsheet_id)
tags_file_google_drive <- as.data.frame(gsheet::gsheet2tbl(url))



# #Load annotation table
# # 1qT9j398DhTmvBvBd0FZvoesy3kMkOta96YZQVhT5Tjw
# list_images_with_tags_and_labels <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1eFJq003Z3JayIHtgupYfM01qV2IVT3VuBeYt6a0OKdM/edit?usp=sharing"))
# # list_images_with_tags_and_labels <- as.data.frame(gsheet::gsheet2tbl("https://drive.google.com/open?id=1TkX5P7pr5MEvxr7J78tCMKrSGzqUSG-FXicod9yLCEc"))
# cat("Update annotations in the database with the content of this google sheet \n")
# # update_annotations_in_database(con_Reef_database, codes_directory, list_images_with_tags_and_labels, create_table=FALSE)



# wd_copy <- "/media/julien/Deep_Mapping_two/trash"
training_images <- "/tmp/training_dataset"
dir.create(training_images)
# We load the mapping between annotation and labels from either a csv or a google sheet
# all_categories <- read.csv("/home/julien/Bureau/CODES/Deep_mapping/CSV/All_categories.csv",stringsAsFactors = FALSE)

all_categories <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1mBQiokVvVwz3ofDGwQFKr3Q4EGnn8nSrA1MEzaFIOpc/edit?usp=sharing"))
# df_images <-all_files
df_images <-read.csv(tags_as_csv)
df_images <-read.csv(all_tags_as_csv)
# head(df_images)
# newdf$path
df_images$path <- gsub("/media/juldebar/Deep_Mapping_4To/data_deep_mapping/all_txt_gps_files","/media/juldebar/Deep_Mapping_4To/data_deep_mapping",df_images$path)
crop_images=FALSE
# we make a copy of all annotated images
copy_images_for_training(training_images, df_images,all_categories,crop_images=crop_images)
# ckeck if sub-repositories exist


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
