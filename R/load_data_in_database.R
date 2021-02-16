# rm(list=ls())
codes_directory <-"~/Desktop/CODES/Deep_mapping/"
source(paste0(codes_directory,"R/credentials_databases.R"))
setwd(codes_directory)

# configuration_file <- paste0(codes_directory,"geoflow/Deep_mapping_worflow.json")
codes_github_repository=codes_directory
source(paste0(codes_github_repository,"R/functions.R"))
# source(paste0(codes_github_repository,"R/gpx_to_wkt.R"))
source(paste0(codes_github_repository,"R/get_session_metadata.R"))
#warning: no slash at the end of the path
# set_time_zone <- dbGetQuery(con_Reef_database, "SET timezone = 'UTC+04:00'")

cat("Connect the database\n")
con_Reef_database <- dbConnect(drv = DRV,dbname=Dbname, host=Host, user=User,password=Password)
cat("Replace the database\n")
# create_database(con_Reef_database, codes_github_repository)

#if multiple missions, list sub-repositories
missions <- list.dirs(path = images_directory, full.names = TRUE, recursive = FALSE)
#if only one mission, indicate the specific sub-repository
# missions <- paste0(images_directory,"/","session_2019_10_12_kite_Le_Morne")
# missions <- "/media/julien/3362-6161/saved/session_2019_09_12_kite_Le_Morne"
load_metadata_in_database=TRUE
load_data_in_database=FALSE
load_tags_in_database=FALSE
upload_to_google_drive=FALSE

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
      metadata_this_mission <- get_session_metadata(con_database=con_Reef_database, session_directory=md, google_drive_path,metadata_sessions=metadata_this_mission,type_images=type_images,google_drive_upload=upload_to_google_drive)
      load_DCMI_metadata_in_database(con_Reef_database, codes_directory, metadata_this_mission,create_table=FALSE)
      ratio <- load_data_in_database(con_database=con_Reef_database, codes_directory, mission_directory=md, platform)
      }
    }else{
      type_images <- "gopro"
      platform <- "kite"
      
      cat(paste0("Processing mission: ", m,"\n"))
      setwd(m)
      session_id <- gsub(paste0(dirname(m),"/"),"",m)
      
      cat(paste0("Extracting dynamic metadata: ", m,"\n"))
      metadata_this_mission <- get_session_metadata(con_database=con_Reef_database, session_directory=m, google_drive_path,metadata_sessions=metadata_this_mission,type_images=type_images)
      cat(paste0("Upload metadata on google drive: ", m,"\n"))
      file_name <- paste0(session_id,"_DCMI_metadata.csv")
      write.csv(metadata_this_mission,file = file_name,row.names = F)
      # googledrive::drive_update(file=DCMI_metadata_google_drive_path,name=file_name,media=file_name)
      if(upload_to_google_drive){
        metadata_gsheet_id <- upload_file_on_drive_repository(DCMI_metadata_google_drive_path,media=file_name, file_name=file_name,type="spreadsheet")
      }
      
      if(load_metadata_in_database){
        cat(paste0("Loading dynamic metadata in the database: ", m,"\n"))
        load_DCMI_metadata_in_database(con_database=con_Reef_database, codes_directory, DCMI_metadata=metadata_this_mission[,c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17)],create_table=FALSE)
      }
      if(load_data_in_database){      
        cat(paste0("Extract and load exif metadata in the database: ", m,"\n"))
        ratio <- NULL
        ratio <- load_exif_metadata_in_database(con_database=con_Reef_database, codes_directory=codes_directory, mission_directory=m,platform)
        # lapply(ratio,class)
      }
      if(load_tags_in_database){      
        cat(paste0("Load tags of photos in the database: ", m,"\n"))
        tags_as_csv <- return_dataframe_tag_txt(m)
        file_name <- paste0(session_id,"_tag.csv")
        if(upload_to_google_drive){
          tags_gsheet_id <- upload_file_on_drive_repository(tags_folder_google_drive_path,media=tags_as_csv, file_name,type="spreadsheet")
          url <-paste0("https://docs.google.com/spreadsheets/d/",tags_gsheet_id)
          tags_file_google_drive <- as.data.frame(gsheet::gsheet2tbl(url))
        }
        
        # query <-update_annotations_in_database(con_database=con_Reef_database, images_tags_and_labels=tags_file_google_drive)
      }
    }
  
  # metadata_this_mission$Comment <- paste0("Ratio d'images géoréférencées: ",ratio[1]/ratio[2], "(images géoréférencées: ", ratio[1]," pour un total d'images de : ", ratio[2],")")
  # metadata_this_mission$Nb_photos_located <- ratio[1]
  # this_file_name <-paste0("metadata_",session_id,".csv")
  # write.csv(metadata_this_mission,file = this_file_name,row.names = F)
  # if(c==1){
  #   metadata_missions <- metadata_this_mission
  # }else{
  #   metadata_missions <- rbind(metadata_missions,metadata_this_mission)
  #   }
}

#write metadata table
setwd(images_directory)
file_name <-"metadata_all_sessions.csv"
write.csv(metadata_missions,file = file_name,row.names = F)
# googledrive::drive_update(file=DCMI_metadata_google_drive_path,name=file_name,media=file_name)
upload_file_on_drive_repository(google_drive_path=google_drive_path,media=file_name,file_name=file_name,type=NULL)
ratio
cat(paste0("Ratio of geolocated images / Total number of images : ",ratio[1]/ratio[2]))

#Number of mission processed in the iteration
nrow(metadata_missions)
#Sum of images processed in the iteration
sum(metadata_missions$Number_of_Pictures)
  
#Disconnect database
dbDisconnect(con_Reef_database)

########################################################################################################################
################### Run geoflow to load Geonetwork and Geoserver #######################
########################################################################################################################
# google_drive_path <- drive_get(id="0B0FxQQrHqkh0NnZ0elY5S0tHUkJxZWNLQlhuQnNGOE15YVlB")
google_drive_path <- drive_get(id="1gUOhjNk0Ydv8PZXrRT2KQ1NE6iVy-unR")

# drive_download("Deep_mapping_worflow.json")
setwd("~/Desktop/CODES/Deep_mapping/geoflow")
configuration_file <- "Deep_mapping_worflow.json"

# initWorkflow(file = configuration_file)
executeWorkflow(file = configuration_file)
upload_file_on_drive_repository(google_drive_path,configuration_file)


########################################################################################################################
################### Manage annotation by selecting photos from database #######################
########################################################################################################################
setwd(tempdir())
dir.create("candidates_training")
setwd("./candidates_training")
# expected_species <- "Sargassum ilicifolium"   "Acropora formosa" "Acropora hyacinthus" "Holoturian"
expected_species <- "slope"
wd_species <- gsub(" ","_", expected_species)
dir.create(gsub(" ","_", expected_species))
training_images <- paste0(tempdir(),'/candidates_training/',wd_species)
wkt <- "Polygon ((57.33188010929304568 -20.3911917018559663, 57.32982081703826083 -20.39321473682830899, 57.32950400284521919 -20.3942726436252002, 57.32980101615118684 -20.39497791078869326, 57.32986041881238748 -20.39594300799250348, 57.32958320639348671 -20.39633275707297955, 57.32859316204022093 -20.39809589535819967, 57.32754371502575452 -20.3991908868742442, 57.3255438254321632 -20.40160355258031899, 57.32491019704607282 -20.40227166871073194, 57.32393995357987393 -20.40290266461765256, 57.32352413495149079 -20.40435023369625256, 57.32269249769475294 -20.40564932256855002, 57.32263309503355231 -20.40611328022464477, 57.3230885154360692 -20.40633597940312782, 57.32417756422466226 -20.40449870155048728, 57.32459338285302408 -20.40301401656821056, 57.32659327244662961 -20.40134372885816205, 57.32716749817150514 -20.4003786654821333, 57.32980101615118684 -20.39833716534372243, 57.33045444542435121 -20.39614716239569958, 57.33041484365022455 -20.39438400181295918, 57.33051384808555895 -20.3935859330226279, 57.33217712259903465 -20.39113602161886263, 57.33217712259903465 -20.39113602161886263, 57.33188010929304568 -20.3911917018559663))"
# wkt="none"

# We extract all images which are within a given polygon (if none => all images) and are not annotated yet and copy these images in a folder whose name is the name of expected category
extracted_images_not_annotated <- spatial_extraction_of_pictures_and_copy_in_tmp_folder(wd=training_images, con_database=con_Reef_database,codes_directory=codes_directory,images_directory=images_directory,wkt=wkt,expected_species=expected_species)
nrow(extracted_images_not_annotated)

#after selecting and moving manually images with the expected category within another folder with the same name we insert these new annotations in the database
mime_type = "*.JPG"
expected_species <- "Sand"
wd_selected_candidates <-paste0("/home/julien/Desktop/Data/candidates/",gsub(" ","_", expected_species))
wd_selected_candidates
insert_images_tags_and_labels <- turn_list_of_files_into_csv_annotated(con_database=con_Reef_database,wd_selected_candidates,extracted_images_not_annotated,expected_species=expected_species,mime_type = "*.JPG")

# => REFRESH VIEW annotation
query1 <-   paste(readLines(paste0(codes_directory,"SQL/create_view_spatial_buffer_species.sql")), collapse=" ")
query1 <-   paste("REFRESH MATERIALIZED VIEW public.view_occurences_manual_annotation")
dbGetQuery(con_Reef_database,query1)

########################################################################################################################
################### Manage annotation #######################
########################################################################################################################


#Merge all manual tags from different sessions
images_directories<- c("/media/julien/Storage_SSD/Data_Deep_Mapping","/home/julien/Desktop/Data/Data_Deep_Mapping")
all_tags_as_csv <- return_dataframe_tag_txt(wd=images_directories,all_categories)
file_name <- "all_sessions_tags"
all_tags_gsheet_id <- upload_file_on_drive_repository(tags_folder_google_drive_path,media=all_tags_as_csv, file_name,type="spreadsheet")
url <-paste0("https://docs.google.com/spreadsheets/d/",all_tags_gsheet_id)
# url <- "https://docs.google.com/spreadsheets/d/1ckFxpNi8XYnlgWtXf0IAf3nSRiuN0mUJ4D8SBD5YVjo"
tags_file_google_drive <- as.data.frame(gsheet::gsheet2tbl(url))
colnames(tags_file_google_drive)
nrow(tags_file_google_drive)
copy_images_for_training(training_images, tags_file_google_drive,file_categories=all_categories,crop_images=FALSE)


dataframe_from_db <- extraction_annotated_pictures_from_db(con_database=con_Reef_database,codes_directory,images_directory)
file_name <- "all_sessions_tags_from_db"
all_tags__from_db_gsheet_id <- upload_file_on_drive_repository(google_drive_path=tags_folder_google_drive_path,media=dataframe_from_db, file_name,type="spreadsheet")
url_db <-paste0("https://docs.google.com/spreadsheets/d/",all_tags__from_db_gsheet_id)
tags_from_db_file_google_drive <- as.data.frame(gsheet::gsheet2tbl(url_db))
colnames(tags_from_db_file_google_drive)
nrow(tags_from_db_file_google_drive)
copy_images_for_training(training_images, tags_from_db_file_google_drive,file_categories=all_categories,crop_images=FALSE)


all_tags <- rbind(tags_file_google_drive,tags_from_db_file_google_drive) %>%  distinct()
nrow(all_tags)
# query <-update_annotations_in_database(con_database=con_Reef_database, images_tags_and_labels=tags_file_google_drive)
query <-update_annotations_in_database(con_database=con_Reef_database, images_tags_and_labels=all_tags)
create_view_species_occurences(con_database=con_Reef_database,codes_directory=codes_directory,images_directory=images_directory)
# all_tags %>%  filter(tag=="Sargassum ilicifolium")


query_annotated_pictures_database <-   paste(readLines(paste0(codes_directory,"SQL/count_annotation_by_species.sql")), collapse=" ")
summary_annotated_pictures_database <- dbGetQuery(con_Reef_database,query_annotated_pictures_database)
file_name <- "Annotated_pictures_database"
all_tags__from_db_gsheet_id <- upload_file_on_drive_repository(google_drive_path=tags_folder_google_drive_path,media=summary_annotated_pictures_database, file_name,type="spreadsheet")





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
df_images <-read.csv(all_tags_as_csv)
# head(df_images)
# newdf$path
df_images$path <- gsub("/media/juldebar/Deep_Mapping_4To/data_deep_mapping/all_txt_gps_files","/media/juldebar/Deep_Mapping_4To/data_deep_mapping",df_images$path)
crop_images=FALSE
# we make a copy of all annotated images
copy_images_for_training(training_images, df_images,all_categories,crop_images=crop_images)
# ckeck if sub-repositories exist


all_tags_as_csv <- return_dataframe_tag_txt(images_directory,all_categories = all_categories)
df_images <-read.csv(all_tags_as_csv)
# df_images <-read.csv("/tmp/Rtmp37F9m2/all_files_combined.csv")
distinct_tags_df_images <- df_images %>% select(tag, tag) %>% distinct()
distinct_tags_df_images
copy_images_for_training(training_images, df_images,all_categories,crop_images=crop_images)
# query <-update_annotations_in_database(con_database=con_Reef_database, images_tags_and_labels=tags_file_google_drive)
query <-update_annotations_in_database(con_database=con_Reef_database, images_tags_and_labels=df_images)
create_view_species_occurences(con_database=con_Reef_database,codes_directory=codes_directory,images_directory=images_directory)




test_toto <- publish_annotated_photos_in_gsheet(con_database=con_Reef_database,google_drive_path=tags_folder_google_drive_path)
tags_file_google_drive <- as.data.frame(gsheet::gsheet2tbl(paste0("https://docs.google.com/spreadsheets/d/",test_toto)))
colnames(tags_file_google_drive)

grade_A<-NULL
grade_A <-data.frame(file_name=c("session_2019_09_20_kite_Le_Morne_avec_Manu_G0069658.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0069659.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0069660.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0072613.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0072616.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0076810.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0076811.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0076812.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077374.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077375.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077408.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077422.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077430.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077434.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077435.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077525.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077526.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077527.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077533.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077533.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077533.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077611.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077612.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077625.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077641.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077661.JPG",
                                 "session_2019_09_20_kite_Le_Morne_avec_Manu_G0077890.JPG",
                                 "session_2019_09_23_kite_lagoon_le_morne_Manu_et_julien_G0027097.JPG",
                                 "session_2019_09_23_kite_lagoon_le_morne_Manu_et_julien_G0027103.JPG",
                                 "session_2019_09_23_kite_lagoon_le_morne_Manu_et_julien_G0027272.JPG",
                                 "session_2019_09_23_kite_lagoon_le_morne_Manu_et_julien_G0027273.JPG",
                                 "session_2019_09_23_kite_lagoon_le_morne_Manu_et_julien_G0027274.JPG",
                                 "session_2019_09_23_kite_lagoon_le_morne_Manu_et_julien_G0028267.JPG",
                                 "session_2019_09_23_kite_lagoon_le_morne_Manu_et_julien_G0029880.JPG",
                                 "session_2019_09_23_kite_lagoon_le_morne_Manu_et_julien_G0031555.JPG",
                                 "session_2019_09_23_kite_lagoon_le_morne_Manu_et_julien_G0032822.JPG",
                                 "session_2019_09_23_kite_lagoon_le_morne_Manu_et_julien_G0032990.JPG",
                                 "session_2019_09_23_kite_lagoon_le_morne_Manu_et_julien_G0033033.JPG",
                                 "session_2019_09_23_kite_lagoon_le_morne_Manu_et_julien_G0033195.JPG",
                                 "session_2019_09_24_kite_Le_Morne_One_Eye_Manawa_Platin_Rouge_Chameau_G0032676.JPG",
                                 "session_2019_09_24_kite_Le_Morne_One_Eye_Manawa_Platin_Rouge_Chameau_G0032754.JPG"))
grade_A$grade <- "A"
colnames(grade_A)
colnames(tags_file_google_drive)

joint_annotated_and_database <- left_join(tags_file_google_drive,grade_A,by = "file_name") %>% distinct()
# %>% mutate(tag =labels$tag_label[l]) 
write.csv(joint_annotated_and_database,file = "joint_annotated_and_database.csv",row.names = F)
setwd("/home/julien/Desktop/sandbox/Thalassodendron_ciliatum")
grade_directories <- joint_annotated_and_database %>% select(grade) %>% distinct()

for(d in grade_directories$grade){
  if(!is.na(d)){
    dir.create(d)
    list_photos <- joint_annotated_and_database %>%  filter(grade==d) %>% select(file_name)
    for(i in 1:nrow(list_photos)){
      filename <- list_photos$file_name[i]
      command <- paste0("mv ", filename,"  ./",d,"\n")
      cat(command)
      system(command)
    }
  }
}



test_toto <- publish_annotated_photos_in_gsheet(con_database=con_Reef_database,google_drive_path=tags_folder_google_drive_path)
tags_file_google_drive <- as.data.frame(gsheet::gsheet2tbl(paste0("https://docs.google.com/spreadsheets/d/",test_toto)))
colnames(tags_file_google_drive)

working_dir <- "/home/julien/Desktop/sandbox/Thalassodendron_ciliatum"
mime_type = "*.JPG"

setwd(working_dir)
grade_directories <- NULL
grade_directories <- data.frame(grade=list.dirs(path=getwd(),full.names = FALSE, recursive = FALSE))
total <- NULL
for(d in grade_directories$grade){
  if(!is.na(d)){
    setwd(paste0(getwd(),"/",d))
    list_photos <- data.frame(file_name=list.files(pattern = mime_type, recursive = FALSE))  %>%  mutate(grade=d)
    list_photos <- left_join(tags_file_google_drive,list_photos,by = "file_name") %>%  filter(grade==d) %>% distinct()
    total <- rbind(total,list_photos)
    setwd(working_dir)
  }
}
nrow(total)
file_name <-"annotated_images_in_database"
metadata_gsheet_id <- upload_file_on_drive_repository(google_drive_path,media=total, file_name=file_name,type="spreadsheet")

