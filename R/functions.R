#############################################################################################################
############################ LOAD PACKAGES ###################################################
########################################################################################################
# library(maps)
# library(reshape)  
# library(geosphere)
# library(leaflet)
#############################################################################################################
###################################### Calculate offset ############################################################
#############################################################################################################
return_offset <- function(con_database, session_metadata){
  
  photo_time <- as.POSIXct(session_metadata$Photo_time)
  GPS_time <- as.POSIXct(session_metadata$GPS_time, tz="UTC")
  photo_time_database <- dbGetQuery(con_database, paste0("select \"DateTimeOriginal\" from photos_exif_core_metadata where \"FileName\"='",session_metadata$Photo_for_calibration,"' AND session_id='",session_metadata$Identifier,"';"))
  photo_time <- as.POSIXct(photo_time_database[,1])
  
  offset <-difftime(photo_time, GPS_time, units="secs")
  return(offset)
}

###################################### LOAD SESSION METADATA ############################################################
#############################################################################################################
sessions_metadata_dataframe <- function(Dublin_Core_metadata){
  all_metadata <- NULL
  
  number_row<-nrow(Dublin_Core_metadata)
  for (i in 1:number_row) {
    # metadata <- Dublin_Core_metadata[i,]
    metadata <- NULL
    
    metadata$session_id  <- Dublin_Core_metadata$Identifier[i]# if(is.na(metadata$Identifier)){metadata$Identifier="TITLE AND DATASET NAME TO BE FILLED !!"}
    metadata$persistent_identifier <- Dublin_Core_metadata$Identifier[i]
    metadata$related_sql_query <- paste0("select * from gps_tracks where session_id='",Dublin_Core_metadata$Identifier[i],"';")
    metadata$related_view_name <- paste("view_", Dublin_Core_metadata$Identifier[i], sep="")
    metadata$identifier <- Dublin_Core_metadata$Identifier[i]
    metadata$title  <- Dublin_Core_metadata$Title[i]
    metadata$contacts_and_roles  <- Dublin_Core_metadata$Creator[i]
    metadata$subject  <- Dublin_Core_metadata$Subject[i]
    metadata$description <- Dublin_Core_metadata$Description[i]
    metadata$date  <- Dublin_Core_metadata$Date[i]
    metadata$type  <- Dublin_Core_metadata$Type[i]
    metadata$format  <- Dublin_Core_metadata$Format[i]
    metadata$language  <- Dublin_Core_metadata$Language[i] #resource_language <- "eng"
    metadata$relation  <- Dublin_Core_metadata$Relation[i] 
    metadata$spatial_coverage  <-  Dublin_Core_metadata$Spatial_Coverage[i]
    metadata$temporal_coverage  <-  Dublin_Core_metadata$Temporal_Coverage[i]
    metadata$rights  <- Dublin_Core_metadata$Rights[i] #UseLimitation <- "intellectualPropertyRights"
    metadata$source  <- "TO BE DONE"
    metadata$provenance  <- Dublin_Core_metadata$Provenance[i]
    metadata$time_offset = as.numeric(Dublin_Core_metadata$Offset[i])
    metadata$geometry_session <- NA
    
    Dublin_Core_metadata$GPS_time[i]
    Dublin_Core_metadata$Photo_time[i]
    
    all_metadata <- bind_rows(all_metadata, metadata)
    # all_metadata <- rbind(all_metadata, metadata)
    
    #complex metadata elements
    #     Creator 
    #     Subject
    #     Relation
    #     Google_doc_folder
    #     Spatial_Coverage
    #     Temporal_Coverage
    #     view_name
    #     GPS_tcx_file  # track_points <- readTCX(file=file, timezone = "GMT")
    #     GPS_gpx_file
    #     Photo_for_GPS_Time_Correlation
    #     Photo_for_calibration
    #     GPS_time
    #     Photo_time
    #     Offset
    #     First_Photo_Correlated
    #     Parameters
    #     
    #     Number_of_photos
    #     Number.of.Pictures
    
    
    # select_columns = subset(track_points, select = c(session,latitude,longitude,altitude,time,heart_rate))
    #   extended_df$session_photo_number <-c(1:nrow(extended_df))
    #   extended_df$relative_path <-"next time"
    #   extended_df <- extended_df[,c(9,10,11,1,2,3,4,5,6,7,8)]
    #   extended_df = rename(extended_df, filename=FileName, gpslatitud=GPSLatitude,gpslongitu=GPSLongitude, gpsdatetim=GPSDateTime, datetimeor=DateTimeOriginal, lightvalue=LightValue, imagesize=ImageSize,	model=Model)
    # write.csv(extended_df, paste("Core_Exif_metadata_", name_session,".csv", sep=""),row.names = F)
    # command <- paste("cp Core_Exif_metadata_DCIM.csv Core_Exif_metadata_", name_session,".csv", sep="")
    # system(command)
    
    
  }
  return(all_metadata)
}
#############################################################################################################
############################ WRITE EXIF METADATA CSV FILES ###################################################
#############################################################################################################
extract_exif_metadata_in_csv <- function(session_id,images_directory,template_df,mime_type,load_metadata_in_database=FALSE,time_zone="Indian/Mauritius"){
  
  setwd(images_directory)
  
  #create directories if they don't exist
    if(!dir.exists(file.path(images_directory, "METADATA"))){
    cat("Create Metadata directory")
    dir.create(file.path(images_directory, "METADATA"))
  }
  setwd(file.path(images_directory, "METADATA"))
  
  metadata_directory <- file.path(getwd(), "exif")
  if(!dir.exists(metadata_directory)){
    cat("Create exif directory")
    dir.create(metadata_directory)
  }
  setwd(images_directory)
  
  sub_directories <- list.dirs(path=getwd(),full.names = TRUE, recursive = TRUE)
  number_sub_directories <-length(sub_directories)
  
  CSV_total <-NULL
  new_exif_metadata <-NULL
  # new_exif_metadata <-template_df
  
  for (i in 1:number_sub_directories){
    # dat <-template_df
    setwd(images_directory)
    this_directory <- sub_directories[i]
      
    # if (endsWith(this_directory, "GOPRO") || endsWith(this_directory, "data")==TRUE || grepl(pattern= "BEFORE",this_directory)==FALSE || grepl(pattern= "AFTER",this_directory)==FALSE){
    if (endsWith(this_directory, "GOPRO") && grepl(pattern= "BEFORE",this_directory)==FALSE && grepl(pattern= "AFTER",this_directory)==FALSE){
      
      setwd(this_directory)
      files <- list.files(pattern = mime_type ,recursive = TRUE)
      # new_exif_metadata <-data.frame()
      
      if(length((files))>0){
        
        cat(paste("\n Metadata extraction for photos in ", this_directory, "\n", sep=" "))
        exif_metadata <- extract_exif_metadata_in_this_directory(session_id,images_directory,this_directory,template_df, mime_type = mime_type, time_zone=time_zone)
        lapply(exif_metadata,class)
        new_exif_metadata <- bind_rows(new_exif_metadata, exif_metadata)
        # CSV_total <- rbind(CSV_total, new_exif_metadata)
        CSV_total <- bind_rows(CSV_total, exif_metadata)
        
        message_done <- paste("\n References for photos in ", this_directory, " have been extracted !\n", sep=" ")
        cat(message_done)
        
        }else if(length(list.files(pattern = "*.MP4" ,recursive = TRUE))>0){
          message_done <- paste("\n Only videos in ", this_directory, " !\n", sep=" ")
          cat(message_done)
          }else{
            message_done <- paste("\n No files with expected mime type in ", this_directory, " !\n", sep=" ")
            cat(message_done)
            }
      setwd(metadata_directory)
    }else{
        cat(paste(this_directory, " has been ignored \n",sep=""))
      }
  }
  
  setwd(metadata_directory)
  name_file_csv<-paste("All_Exif_metadata_",session_id,".csv",sep="")
  # write.csv(CSV_total, name_file_csv,row.names = F)
  saveRDS(CSV_total, paste("All_Exif_metadata_",session_id,".RDS",sep=""))
  
  # return(nrow(read.csv("Core_Exif_metadata.csv")))
  return(CSV_total)
}


# ELEMENTS A TESTER SUR CSV ALL METADATA
# CSV_total$PreviewImage[1] 
# CSV_total$ThumbnailImage[1] 
# CSV_total$ThumbnailOffset[1]
# CSV_total$ThumbnailLength[1]

extract_exif_metadata_in_this_directory <- function(session_id,images_directory, this_directory,template_df, mime_type = "*.JPG", time_zone="Indian/Mauritius"){
  setwd(this_directory)
  
  log <- paste("Adding references for photos in ", this_directory, "\n", sep=" ")
  parent_directory <- gsub(dirname(dirname(dirname(this_directory))),"",dirname(dirname(this_directory)))
  parent_directory <- gsub("/","",parent_directory)
  
  files <- list.files(pattern = mime_type ,recursive = TRUE)
  exif_metadata <- NULL#check if needed
  # exif_metadata <- template_df#check if needed
  # lapply(template_df,class)
  # print(lapply(exif_metadata,class))
  
  exif_metadata <- read_exif(files,quiet=TRUE)#DDD deg MM' SS.SS"
  # exif_metadata <- bind_rows(exif_metadata, template_df)
  
  # print(colnames(exif_metadata))
  print(lapply(exif_metadata$ExposureIndex[1],class))
  # transform(exif_metadata, SourceFile = as.character(SourceFile),ExposureIndex = as.numeric(ExposureIndex))
  exif_metadata$ExposureIndex <- as.numeric(as.character(exif_metadata$ExposureIndex))
  # lapply(exif_metadata,class)
  
  exif_metadata$session_id = session_id
  exif_metadata$session_photo_number <-c(1:nrow(exif_metadata))
  exif_metadata$relative_path = gsub(dirname(images_directory),"",this_directory)
  # # IF THERE IS NO EMBEDDED GPS DATA WE ADD EXPECTED COLUMNS WITH DEFAULT VALUES ("NA")
  if(is.null(exif_metadata$GPSDateTime)==TRUE){
    exif_metadata$GPSDateTime <-NA
  }
  if(is.null(exif_metadata$GPSLatitude)==TRUE){
    # "GPSLatitude" %in% colnames(exif_metadata)
    exif_metadata$GPSVersionID <-NA
    exif_metadata$GPSLatitudeRef <-NA
    exif_metadata$GPSLongitudeRef <-NA
    exif_metadata$GPSAltitudeRef <-NA
    exif_metadata$GPSTimeStamp <-NA
    exif_metadata$GPSMapDatum <-NA
    exif_metadata$GPSDateStamp <-NA
    exif_metadata$GPSAltitude <-NA
    exif_metadata$GPSDateTime <-NA
    # exif_metadata$GPSDateTime <-"1977:06:18 10:00:00"
    exif_metadata$GPSLatitude <-NA
    exif_metadata$GPSLongitude <-NA
    exif_metadata$GPSPosition <-NA
  }
  # change default data types
  # exif_metadata$GPSDateTime = as.POSIXct(unlist(exif_metadata$GPSDateTime),"%Y:%m:%d %H:%M:%SZ", tz="UTC")
  if(platform=="drone"){
    exif_metadata$GPSDateTime = with_tz(as.POSIXct(unlist(exif_metadata$DateTimeOriginal),"%Y:%m:%d %H:%M:%SZ",  tz="UTC"), "UTC")
  }else{
    exif_metadata$GPSDateTime = with_tz(as.POSIXct(unlist(exif_metadata$GPSDateTime),"%Y:%m:%d %H:%M:%SZ",  tz="UTC"), "UTC")
  }
  # exif_metadata$Raw_Time_Julien = exif_metadata$DateTimeOriginal
  exif_metadata$DateTimeOriginal = with_tz(as.POSIXct(unlist(exif_metadata$DateTimeOriginal),"%Y:%m:%d %H:%M:%S", tz=time_zone), "UTC")
  # exif_metadata$DateTimeOriginal <- format(exif_metadata$DateTimeOriginal, tz="UTC",usetz=TRUE)
  attr(exif_metadata$DateTimeOriginal,"tzone")
  # exif_metadata$GPSLatitude = as.numeric(exif_metadata$GPSLatitude)
  # exif_metadata$GPSLongitude = as.numeric(exif_metadata$GPSLongitude)
  exif_metadata$geometry_postgis <- NA
  exif_metadata$geometry_postgis = as.numeric(unlist(exif_metadata$geometry_postgis))
  exif_metadata$geometry_gps_correlate <- NA
  exif_metadata$geometry_gps_correlate = as.numeric(unlist(exif_metadata$geometry_gps_correlate))
  exif_metadata$geometry_native <- NA
  exif_metadata$geometry_native = as.numeric(unlist(exif_metadata$geometry_native))
  # lapply(exif_metadata,class)
  
  return(exif_metadata)
}

#############################################################################################################
############################ RETRIEVE CSV EXIF METADATA FILES ###################################################
#############################################################################################################
return_dataframe_csv_exif_metadata_files <- function(wd){
  setwd(wd)
  dataframe_csv_files <- NULL
  dataframe_csv_files <- data.frame(session=character(), path=character(), file_name=character())
  sub_directories <- list.dirs(path=wd,full.names = TRUE,recursive = TRUE)
  sub_directories  
  for (i in sub_directories){
    if (substr(i, nchar(i)-3, nchar(i))=="exif"){
      setwd(i)
      name_session <-gsub(paste(dirname(dirname(dirname(i))),"/",sep=""),"",dirname(dirname(i)))
      files <- list.files(pattern = "*.csv")
      csv_files <- files
      cat(dirname(i))
      newRow <- data.frame(session=name_session,path=i,file_name=csv_files)
      dataframe_csv_files <- rbind(dataframe_csv_files,newRow)
    } else {
      cat("\ CHECK\n")
      cat(i)
      cat("\n")
    }
  }
  return(dataframe_csv_files)
}
#############################################################################################################
############################ RENAME CSV FILES ###################################################
#############################################################################################################
rename_exif_csv <- function(images_directory){
  metadata_directory <- paste(images_directory,"/exif/",sep="")
  setwd(metadata_directory)
  name_session <-gsub(paste(dirname(images_directory),"/",sep=""),"",images_directory)
  extended_df <- read.csv("Core_Exif_metadata_DCIM.csv")
  extended_df$session_id <-name_session
  extended_df$session_photo_number <-c(1:nrow(extended_df))
  extended_df$relative_path <-"next time"
  extended_df <- extended_df[,c(9,10,11,1,2,3,4,5,6,7,8)]
  extended_df = rename(extended_df, filename=FileName, gpslatitud=GPSLatitude,gpslongitu=GPSLongitude, gpsdatetim=GPSDateTime, datetimeor=DateTimeOriginal, lightvalue=LightValue, imagesize=ImageSize,	model=Model)
  
  
  write.csv(extended_df, paste("Core_Exif_metadata_", name_session,".csv", sep=""),row.names = F)
  
  # command <- paste("cp Core_Exif_metadata_DCIM.csv Core_Exif_metadata_", name_session,".csv", sep="")
  # system(command)
}


#############################################################################################################
############################ create_database ###################################################
#############################################################################################################

create_database <- function(con_database, codes_directory){
  
  query_create_database <- paste(readLines(paste0(codes_directory,"SQL/create_Reef_database.sql")), collapse=" ")
  query_create_database <- gsub("Reef_admin",User,query_create_database)
  create_database <- dbGetQuery(con_database,query_create_database)
  
  query_create_table_metadata <- paste(readLines(paste0(codes_directory,"SQL/create_Dublin_Core_metadata.sql")), collapse=" ")
  query_create_table_metadata <- gsub("Reef_admin",User,query_create_table_metadata)
  create_table_metadata <- dbGetQuery(con_database,query_create_table_metadata)
  
  query_create_table_gps_tracks <- paste(readLines(paste0(codes_directory,"SQL/create_table_GPS_tracks.sql")), collapse=" ")
  query_create_table_gps_tracks <- gsub("Reef_admin",User,query_create_table_gps_tracks)
  create_table <- dbGetQuery(con_database,query_create_table_gps_tracks)
  
  query_create_table_exif_metadata <- paste(readLines(paste0(codes_directory,"SQL/create_exif_metadata_table.sql")), collapse=" ")
  query_create_table_exif_metadata <- gsub("Reef_admin",User,query_create_table_exif_metadata)
  create_table_exif_metadata <- dbGetQuery(con_database,query_create_table_exif_metadata)
  
  query_create_table_label <- paste(readLines(paste0(codes_directory,"SQL/create_label_table.sql")), collapse=" ")
  query_create_table_label <- gsub("Reef_admin",User,query_create_table_label)
  create_table_label <- dbGetQuery(con_database,query_create_table_label)
  labels <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1mBQiokVvVwz3ofDGwQFKr3Q4EGnn8nSrA1MEzaFIOpc/edit?usp=sharing"))
  tags_to_be_loaded <- labels %>% select(SubName,TagName, Link) %>% distinct() %>% rename(tag_code = TagName, tag_label = SubName, tag_definition=Link) %>% mutate(tag_id = row_number()) %>% relocate(tag_id,tag_code,tag_label,tag_definition)
  load_labels_in_database(con_database, codes_directory, tags_to_be_loaded, create_table=FALSE)
  
} 

#############################################################################################################
############################ load_labels_in_database ###################################################
#############################################################################################################

load_labels_in_database <- function(con_database, codes_directory, labels, create_table=FALSE){
  
  if(create_table==TRUE){
    query_create_table_label <- paste(readLines(paste0(codes_directory,"SQL/create_label_table.sql")), collapse=" ")
    query_create_table_label <- gsub("Reef_admin",User,query_create_table_label)
    create_table_label <- dbGetQuery(con_database,query_create_table_label)
  }
  
  dbWriteTable(con_database, "label", labels, row.names=FALSE, append=TRUE)
  
}

#############################################################################################################
############################ load_annotation_in_database ###################################################
#############################################################################################################
# load images and tags for original images
update_annotations_in_database <- function(con_database, images_tags_and_labels){
  
  # labels <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1mBQiokVvVwz3ofDGwQFKr3Q4EGnn8nSrA1MEzaFIOpc/edit?usp=sharing"))
  query_labels <- paste0('SELECT * FROM public.label ;')
  labels <- dbGetQuery(con_database, query_labels)
  
  #list different sessions and identifiers for annnotated photos to extract additional info from database
  list_sessions <- images_tags_and_labels %>% select(file_name, name_session) %>% distinct(images_tags_and_labels$name_session) %>% as.character()
  list_sessions <-  gsub('"', "'", list_sessions, fixed=TRUE)
  list_sessions <-  gsub("c\\(","", list_sessions)
  list_sessions <- gsub("\\)","",list_sessions)
  list_photo_identifier <- images_tags_and_labels %>% select(file_name, name_session) %>% distinct(images_tags_and_labels$photo_name) %>% as.character()
  list_photo_identifier <-  gsub('"', "'", list_photo_identifier, fixed=TRUE)
  list_photo_identifier <-  gsub("c\\(","", list_photo_identifier)
  list_photo_identifier <- gsub("\\)","",list_photo_identifier)
  
  #create accordingly the query which will extract all annnotated photos by using as filters the list of different sessions and photos identifiers
  query_annotated_pictures_exif_metadata <- paste(readLines(paste0(codes_directory,"SQL/select_annotated_pictures_exif_metadata.sql")), collapse=" ")
  # query_annotated_pictures_exif_metadata <- gsub("list_photos",list_photos,query_annotated_pictures_exif_metadata)
  query_annotated_pictures_exif_metadata <- gsub("list_sessions",list_sessions,query_annotated_pictures_exif_metadata)
  query_annotated_pictures_exif_metadata <- gsub("list_photo_identifier",list_photo_identifier,query_annotated_pictures_exif_metadata)
  exif_metadata_of_annotated_images <- dbGetQuery(con_database, query_annotated_pictures_exif_metadata)
  colnames(exif_metadata_of_annotated_images)
  colnames(images_tags_and_labels)
  nrow(images_tags_and_labels)
  nrow(exif_metadata_of_annotated_images)
  
  joint_annotated_and_database <- left_join(exif_metadata_of_annotated_images,images_tags_and_labels,by = "photo_name") %>% select(photo_id, photo_name,tag) %>% distinct()
  nrow(joint_annotated_and_database)
  #join the two dataframes to add the "photo_id" column to the "images_tags_and_labels"
  # images_tags_and_labels <- 
   
  #create the query which will fill the "annotation" table in the database by adding the identifier of the label "tag_id"
  query_annotation <-" "
    # select photo with dplyr  
    # query_session_photos <- paste0('SELECT photo_id FROM public.photos_exif_core_metadata WHERE "session_id"=\'',session_id,'\' AND "FileName"=\'',FileName,'\';')
    # related_image <- dbGetQuery(con_database, query_session_photos)
    for(l in 1:nrow(labels)){
      relevant_images <-NULL
      relevant_images <- joint_annotated_and_database %>% filter(str_detect(str_to_lower(tag), str_to_lower(labels$tag_label[l]))) %>% mutate(tag =labels$tag_label[l]) %>% distinct()
      
      if(nrow(relevant_images)>=1){
          for(r in 1:nrow(relevant_images)){
            # cat(paste0("\n The label ",labels$tag_label[l]," has been found in annotation of picture: ",relevant_images$photo_name[r],"\n"))
            query_annotation_line <- paste0('INSERT INTO annotation VALUES (\'',relevant_images$photo_id[r],'\',\'',l,'\');')
              query_annotation <- paste0(query_annotation_line,"\n",query_annotation)

          }
        }
    
    
    # if(nrow(relevant_images)==1){
    #   cat(paste0("\n The picture annotated: ",session_id,"_",FileName," is in the database ! \n"))
    #   cat(relevant_images$FileName)
    #   # get primary key of this image in the database
    #   photo_id <- relevant_images$photo_id
    #   # tag_id <- strsplit(",",gsub(" ","",images_tags_and_labels$tag[i]))
    #   # tag_id <- 1
    #   for(l in 1:nrow(labels)){
    #     if(grepl(pattern = labels$tag_label[l], x=tag)){
    #       cat(paste0("\n The label ",labels$tag_label[l]," has been found in annotation of picture: ",FileName,"\n"))
    #       query_annotation_line <- paste0('INSERT INTO annotation VALUES (\'',photo_id,'\',\'',l,'\');\n')
    #       query_annotation <- paste0(query_annotation_line,query_annotation)
    #       }
    #     }
    #   }else if(nrow(relevant_images)==0){
    #   cat(paste0("\n The picture annotated: ",session_id,"_",FileName," is not in the database ! \n"))
    #   }else if(nrow(relevant_images)>1){
    #     cat(paste0("\n this would mean that the picture: ",session_id,"_",FileName," is stored multiple times ! \n"))
    #     }
      
  }
  fileConn<-file(paste0('query_annotation.SQL'))
  writeLines(query_annotation, fileConn)
  close(fileConn)
  relevant_images <- dbGetQuery(con_database, query_annotation)

  return(query_annotation)
}

#############################################################################################################
############################ load_DCMI_metadata_in_database ###################################################
#############################################################################################################


load_DCMI_metadata_in_database <- function(con_database, codes_directory, DCMI_metadata, create_table=FALSE){
  
  if(create_table==TRUE){
    
    query_create_table_metadata <- paste(readLines(paste0(codes_directory,"SQL/create_Dublin_Core_metadata.sql")), collapse=" ")
    query_create_table_metadata <- gsub("Reef_admin",User,query_create_table_metadata)
    create_table_metadata <- dbGetQuery(con_database,query_create_table_metadata)
    
  }
  test <- dbGetQuery(con_database, paste0('SELECT * FROM public.metadata WHERE "Identifier"=\'',DCMI_metadata$Identifier,'\';'))
  if(nrow(test)==1){
    dbGetQuery(con_database, paste0('UPDATE public.metadata SET "TemporalCoverage"=\'',DCMI_metadata$TemporalCoverage,'\', "Data"=\'',DCMI_metadata$Data,'\' WHERE "Identifier"=\'',DCMI_metadata$Identifier,'\';'))
  }else{
    dbWriteTable(con_database, "metadata", DCMI_metadata, row.names=FALSE, append=TRUE)
    }
  
  existing_rows <- dbGetQuery(con_database, paste0('UPDATE metadata SET geometry = ST_GeomFromText("SpatialCoverage",4326);'))
  
  
}

#############################################################################################################
############################ load_exif_metadata_in_database ###################################################
#############################################################################################################

load_exif_metadata_in_database <- function(con_database, codes_directory, core_exif_metadata, create_table=FALSE){
  if(create_table==TRUE){
    query_create_exif_core_metadata_table <- paste(readLines(paste0(codes_github_repository,"SQL/create_exif_metadata_table.sql")), collapse=" ")
    create_exif_core_metadata_table <- dbGetQuery(con_database,query_create_exif_core_metadata_table)
    dbWriteTable(con_database, "photos_exif_core_metadata", core_exif_metadata, row.names=FALSE, append=TRUE)
  } else {
    photo_id_min <- dbGetQuery(con_database, paste0("SELECT max(photo_id) FROM photos_exif_core_metadata;"))+1
    if(is.na(photo_id_min)){
      photo_id_min=1
      }
    photo_id_max <- max(photo_id_min)+nrow(core_exif_metadata)-1
    core_exif_metadata$photo_id <-c(max(photo_id_min):photo_id_max)
    names(core_exif_metadata)
    # core_exif_metadata <- core_exif_metadata[,c(15,1,2,3,4,5,6,7,8,9,10,11,12,13,14)]
    dbWriteTable(con_database, "photos_exif_core_metadata", core_exif_metadata, row.names=FALSE, append=TRUE)
  }
  query_update_table_spatial_column <- paste(readLines(paste0(codes_directory,"SQL/add_spatial_column_exif_metadata.sql")), collapse=" ")
  update_Table <- dbGetQuery(con_database,query_update_table_spatial_column)
  return (cat("\n Exif data succesfully loaded in Postgis !\n"))
  
  # dbWriteTable(con_database, "photos_exif_core_metadata", All_Core_Exif_metadata[1:10,], row.names=TRUE, append=TRUE)
}

#############################################################################################################
############################ load_gps_tracks_in_database ###################################################
#############################################################################################################

load_gps_tracks_in_database <- function(con_database, codes_directory, gps_tracks, create_table=TRUE){
  if(create_table==TRUE){
    query_create_table <- paste(readLines(paste0(codes_directory,"SQL/create_table_GPS_tracks.sql")), collapse=" ")
    create_Table <- dbGetQuery(con_database,query_create_table)
    dbWriteTable(con_database, "gps_tracks", gps_tracks, row.names=FALSE, append=TRUE)
  } else {
    dbWriteTable(con_database, "gps_tracks", gps_tracks, row.names=FALSE, append=TRUE)
  }
  query_update_table_spatial_column <- paste(readLines(paste0(codes_directory,"SQL/add_spatial_column.sql")), collapse=" ")
  update_Table <- dbGetQuery(con_database,query_update_table_spatial_column)
  return (cat("\nGPS data succesfully loaded in Postgis !\n"))
  # return (update_Table)
}


#############################################################################################################
############################ infer_photo_location_from_gps_tracks ###################################################
#############################################################################################################
# Create or replace a SQL materialized view to gather data per dataset / survey

infer_photo_location_from_gps_tracks <- function(con_database, images_directory, codes_directory, session_id, platform, offset, create_view=FALSE){
  original_directory <- getwd()
  setwd(images_directory)
  # query <- NULL
  # query <- paste(readLines(paste0(codes_directory,"SQL/template_interpolation_between_closest_GPS_POINTS_new.sql")), collapse=" ")
  # query <- gsub(" CREATE MATERIALIZED VIEW IF NOT EXISTS","CREATE MATERIALIZED VIEW IF NOT EXISTS",query)
  # query <- gsub("session_2018_03_24_kite_Le_Morne",session_id,query)
  # if(offset < 0){
  #   query <- gsub("- interval","+ interval",query)
  #   query <- gsub("41",abs(offset)+1,query)
  #   # query <- gsub("41",abs(offset)+2,query)
  #   query <- gsub("42",abs(offset),query)
  # }else{
  #   query <- gsub("41",abs(offset)-1,query)
  #   query <- gsub("42",abs(offset),query)
  # }
  # fileConn<-file(paste0('view_',session_id,'.SQL'))
  # writeLines(query, fileConn)
  # close(fileConn)
  # inferred_location <- dbGetQuery(con_database, query)
  # 
  
  ###########################################################
  ###########################################################
  create_table_from_view <-NULL
  
  if(platform =="drone"){
    cat("/ntoto/n")
    create_table_from_view <- gsub("replace_session_id",session_id,paste(readLines(paste0(codes_directory,"SQL/create_table_from_exif_table.sql")), collapse=" "))
    fileConn<-file(paste0('table_',session_id,'.SQL'))
    writeLines(create_table_from_view, fileConn)
    close(fileConn)
    
    }else{
      create_table_from_view <- gsub("replace_session_id",session_id,paste(readLines(paste0(codes_directory,"SQL/create_table_from_view.sql")), collapse=" "))
      query <- NULL
      # query <- paste(readLines(paste0(codes_directory,"SQL/template_interpolation_between_closest_GPS_POINTS_new.sql")), collapse=" ")
      query <- paste(readLines(paste0(codes_directory,"SQL/template_interpolation_between_closest_GPS_POINTS_V3.sql")), collapse=" ")
      query_drop <- paste0('DROP MATERIALIZED VIEW IF EXISTS "view_',session_id,'";')
      query <- paste0(query_drop,'CREATE MATERIALIZED VIEW "view_',session_id,'" AS ',query)
      # query <- paste0('CREATE MATERIALIZED VIEW "view_',session_id,'" AS ',query)
      query <- gsub("session_2019_02_16_kite_Le_Morne_la_Pointe",session_id,query)
      if(offset < 0){      
        query <- gsub("- interval","+ interval",query)
        query <- gsub("778",abs(offset)+1,query)
      }else{        
        query <- gsub("778",abs(offset)-1,query)
        }
      query <- paste0(query," WITH DATA")
      dbGetQuery(con_database, query)
      
          fileConn<-file(paste0('view_',session_id,'.SQL'))
          writeLines(query, fileConn)
          close(fileConn)
          }
  result <- dbGetQuery(con_database, create_table_from_view)
  # add_spatial_index <- dbGetQuery(con_database, paste0('DROP INDEX IF EXISTS \"view_',session_id,'_geom_i\" ; CREATE INDEX \"view_',session_id,'_geom_i\" ON \"view_',session_id,'\" USING GIST (the_geom);'))
  add_spatial_index <- dbGetQuery(con_database, paste0('DROP INDEX IF EXISTS \"',session_id,'_geom_idx\" ;  CREATE INDEX \"',session_id,'_geom_idx\" ON \"',session_id,'\" USING GIST (the_geom);'))
  create_csv_from_view <- dbGetQuery(con_database, paste0('SELECT * FROM \"',session_id,'\";'))
  # head(create_csv_from_view)
  setwd(paste0(images_directory,"/GPS"))
  filename <- paste0("photos_location_",session_id,".csv")
  write.csv(create_csv_from_view, filename,row.names = F)
  # shape_file <- write_shp_from_csv(file_name)
  setwd(original_directory)
  
  return(create_csv_from_view)
}

#############################################################################################################
############################ load_data_in_database ###################################################
#############################################################################################################

load_data_in_database <- function(con_database, codes_directory, mission_directory,platform){
  
  
  cat(paste0("Start loading data for mission: ", mission_directory,"\n"))
  
  
  # SET DIRECTORIES & LOAD SOURCES & CONNECT DATABASE
  dataset_time_zone <- "Indian/Mauritius"
  
  # SET DIRECTORIES & LOAD SOURCES & CONNECT DATABASE
  if(type_images=="drone"){
    session_id <- paste0(gsub(paste0(dirname(dirname(mission_directory)),"/"),"",dirname(mission_directory)),"_",gsub(" ","",gsub(paste0(dirname(mission_directory),"/"),"",mission_directory)))
    mime_type = "*.jpg"
    prefix_mission = "Mission"
    images_dir = "./data"
    gps_dir = "./"
    file_type<-"GPX"
    offset <- 0
    
  }else if(type_images=="gopro"){
    session_id <- gsub(" ","",gsub(paste0(dirname(mission_directory),"/"),"",mission_directory))
    mime_type = "*.JPG"
    prefix_mission = "session_"
    gps_dir = "GPS"
    images_dir = "./DCIM"
    file_type<-"TCX" #  "GPX"  "TCX" "RTK"
    
    # Calculate offset between timestamps of the camera and GPS
    con <- file(paste0(mission_directory,"/LABEL/tag.txt"),"r")
    first_line <- readLines(con,n=1)
    close(con)
    offset <- as.numeric(eval(parse(text = sub(".*=> ","",first_line))))
  }
  
  # EXTRACT exif metadata elements & store them in a CSV file & LOAD THEM INTO POSTGRES DATABASE
  all_exif_metadata <-NULL
  # 1) extract exif metadata and store it into a CSV or RDS file
  if(!file.exists(paste0(mission_directory,"/METADATA/exif/All_Exif_metadata_",session_id,".RDS"))){
    # extract exif metadata on the fly
    template_df <- read.csv(paste0(codes_directory,"CSV/All_Exif_metadata_template.csv"),
                            colClasses=c(SourceFile="character",ExifToolVersion="numeric",FileName="character",Directory="character",FileSize="integer",FileModifyDate="character",FileAccessDate="character",FileInodeChangeDate="character",FilePermissions="integer",FileType="character",FileTypeExtension="character",MIMEType="character",ExifByteOrder="character",ImageDescription="character",Make="character",Orientation="integer",XResolution="integer",YResolution="integer",ResolutionUnit="integer",Software="character",ModifyDate="character",YCbCrPositioning="integer",ExposureTime="numeric",FNumber="numeric",ExposureProgram="integer",ISO="integer",ExifVersion="character",DateTimeOriginal="POSIXct",CreateDate="character",ComponentsConfiguration="character",CompressedBitsPerPixel="numeric",ShutterSpeedValue="numeric",ApertureValue="numeric",MaxApertureValue="numeric",SubjectDistance="integer",MeteringMode="integer",LightSource="integer",Flash="integer",FocalLength="integer",Warning="character",FlashpixVersion="character",ColorSpace="integer",ExifImageWidth="integer",ExifImageHeight="integer",InteropIndex="character",InteropVersion="character",ExposureIndex="character",SensingMethod="integer",FileSource="integer",SceneType="integer",CustomRendered="integer",ExposureMode="integer",DigitalZoomRatio="integer",FocalLengthIn35mmFormat="integer",SceneCaptureType="integer",GainControl="integer",Contrast="integer",Saturation="integer",DeviceSettingDescription="character",SubjectDistanceRange="integer",SerialNumber="character",GPSLatitudeRef="character",GPSLongitudeRef="character",GPSAltitudeRef="integer",GPSTimeStamp="character",GPSDateStamp="character",Compression="integer",ThumbnailOffset="integer",ThumbnailLength="integer",MPFVersion="character",NumberOfImages="integer",MPImageFlags="integer",MPImageFormat="integer",MPImageType="integer",MPImageLength="integer",MPImageStart="integer",DependentImage1EntryNumber="integer",DependentImage2EntryNumber="integer",ImageUIDList="character",TotalFrames="integer",DeviceName="character",FirmwareVersion="character",CameraSerialNumber="character",Model="character",AutoRotation="character",DigitalZoom="character",ProTune="character",WhiteBalance="character",Sharpness="character",ColorMode="character",AutoISOMax="integer",AutoISOMin="integer",ExposureCompensation="numeric",Rate="character",PhotoResolution="character",HDRSetting="character",ImageWidth="integer",ImageHeight="integer",EncodingProcess="integer",BitsPerSample="integer",ColorComponents="integer",YCbCrSubSampling="character",Aperture="numeric",GPSAltitude="numeric",GPSDateTime="POSIXct",GPSLatitude="numeric",GPSLongitude="numeric",GPSPosition="character",ImageSize="character",PreviewImage="character",Megapixels="integer",ScaleFactor35efl="integer",ShutterSpeed="numeric",ThumbnailImage="character",CircleOfConfusion="character",FOV="numeric",FocalLength35efl="integer",HyperfocalDistance="numeric",LightValue="numeric",session_id="character",session_photo_number="integer",relative_path="character",geometry_postgis="numeric",geometry_gps_correlate="numeric",geometry_native="numeric"),
                            stringsAsFactors = FALSE)
    lapply(template_df,class)
    all_exif_metadata <- extract_exif_metadata_in_csv(session_id, images_directory = mission_directory, template_df, mime_type,load_metadata_in_database=FALSE,time_zone=dataset_time_zone)
    lapply(all_exif_metadata,class)
    
  }else{
    # read existing exif metadata from RDS file
    all_exif_metadata <- readRDS(paste0(mission_directory,"/METADATA/exif/All_Exif_metadata_",session_id,".RDS"))
  }
  cat(paste0("Adding attributes \n"))
  
  all_exif_metadata$PreviewImage <- paste0("base64:",base64enc::base64encode("https://upload.wikimedia.org/wikipedia/commons/7/7f/Logo_IRD_2016_BLOC_FR_COUL.png"))
  all_exif_metadata$URL_original_image <-"http://thredds.oreme.org/tmp/Deep_mapping/session_2017_11_19_paddle_Black_Rocks_G0028305.JPG"
  
  cat(paste0("Extracting Core exif metadata \n"))
  core_exif_metadata <-NULL
  if(!is.null(all_exif_metadata)){
    core_exif_metadata <- select(all_exif_metadata,
                                 session_id,
                                 session_photo_number,
                                 relative_path,
                                 FileName,
                                 FileSize,
                                 FileType,
                                 ImageSize,
                                 ExifToolVersion,
                                 GPSLatitude,
                                 GPSLongitude,
                                 GPSDateTime,
                                 DateTimeOriginal,
                                 # Raw_Time_Julien,
                                 LightValue,
                                 ImageSize,
                                 Make,
                                 Model,
                                 geometry_postgis,
                                 geometry_gps_correlate,
                                 geometry_native,
                                 ThumbnailOffset,
                                 ThumbnailLength,
                                 ThumbnailImage,
                                 PreviewImage,                             
                                 URL_original_image                             
                                 
        )
        names(core_exif_metadata)
        # name_file_csv<-paste("Core_Exif_metadata_",session_id,".csv",sep="")
        # saveRDS(core_exif_metadata, paste("Core_Exif_metadata_",session_id,".RDS",sep=""))
        
        cat(paste0("Load the core exif metadata in the SQL database \n"))
        load_exif_metadata_in_database(con_database, codes_directory, core_exif_metadata, create_table=FALSE)

        cat(paste0("Check that the SQL database was properly loaded \n"))
        check_database <- dbGetQuery(con_database, paste0("SELECT * FROM photos_exif_core_metadata WHERE session_id='",session_id,"' LIMIT 10"))
        check_database
        
        # Check offset from pictures with embedded GPS in the camera
        offset_db <-NULL
        sql_query <- paste0('select ("GPSDateTime" - "DateTimeOriginal") AS offset, * FROM photos_exif_core_metadata WHERE "GPSDateTime" IS NOT NULL LIMIT 10')
        # check_offset_from_pictures <- dbGetQuery(con_database,sql_query)
        # check_offset_from_pictures
        
        # Check first if GPS data is embedded in the camera (model not gopro session 5)
        # offset_db <-difftime(check_offset_from_pictures$DateTimeOriginal,check_offset_from_pictures$GPSDateTime,units="secs")
        # offset_db
        
      }else{
        cat("no pictures in this session ! \n")
      }
  
  #EXTRACT GPS TRACKS DATA AND LOAD THEM INTO POSTGRES DATABASE
  # define expected mime type for the search
  # check the number of GPS files for the session (sometimes more than one: battery issue..)
  # Use function "dataframe_gps_files" to list all gps files
  setwd(mission_directory)
  
  if(!dir.exists(file.path(mission_directory, "GPS"))){
    cat("Create GPS directory")
    dir.create(file.path(mission_directory, "GPS"))
  }
  dataframe_gps_files <- NULL
  dataframe_gps_files <- data.frame(session=character(), path=character(), file_name=character())
  
  if(type_images=="drone"){
    gps_files <- list.files(pattern = "\\.gpx$",ignore.case=TRUE)
    file.copy(gps_files, "./GPS")
    newRow <- data.frame(session=session_id,path=mission_directory,file_name=gps_files)
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
      dataframe_gps_file <- return_dataframe_gps_file(con_database, wd=codes_directory, gps_file=gps_file, type=file_type, session_id=session_id)
      duplicates <- distinct(dataframe_gps_file, time)
      duplicates_number <- nrow(dataframe_gps_file)-nrow(duplicates)
      paste0("the file has :", duplicates_number," duplicates")
      load_gps_tracks_in_database(con_database, codes_directory, dataframe_gps_file, create_table=FALSE)
      # generate a thumbnail of the map
      # plot_tcx(gps_file,mission_directory)
      cat("GPS tracks loaded in the database!\n")
    }
  }else(cat("No GPS file when looking for TCX or GPX files => RTK ??"))
  
  # INFER LOCATION OF PHOTOS FROM GPS TRACKS TIMESTAMP
  photo_location <- infer_photo_location_from_gps_tracks(con_database, mission_directory, codes_directory,session_id, platform=platform, offset=offset,create_view=TRUE)
  head(photo_location$the_geom,n = 50)
  
  cat("Materialized view has been created!\n")
  
  paste0("For a total of ",nrow(all_exif_metadata), " photos")
  paste0(nrow(photo_location), " photos have been located from GPS tracks")
  ratio = nrow(photo_location) / nrow(all_exif_metadata)
  ratio <-c(nrow(photo_location),nrow(all_exif_metadata))
  nrow(dataframe_gps_file)
  
  return(ratio)
}

#############################################################################################################
############################ READ the file storing GPS data ###################################################
#############################################################################################################
return_dataframe_gps_file <- function(con_database, wd, gps_file, type="TCX",session_id,load_in_database=FALSE){
  setwd(wd)
  track_points <- NULL
  track_points=switch(type,
         "RTK" = read.csv(gps_file,stringsAsFactors = FALSE),
         "GPX" = rgdal::readOGR(dsn = gps_file, layer="track_points",stringsAsFactors = FALSE),
         "TCX" = readTCX(file=gps_file, timezone = "UTC")
  )
  head(track_points)
  # sapply(track_points,class)
  slotNames(track_points)
  existing_rows_session <-NULL
  # if(load_in_database==TRUE){
  existing_rows_session <- dbGetQuery(con_database, paste0("SELECT COUNT(*) FROM gps_tracks WHERE session_id='",session_id,"';"))
  existing_rows=dbGetQuery(con_database, paste0("SELECT COUNT(*) FROM gps_tracks;"))
  # }
  if(existing_rows_session$count==0){
    # existing_rows=0
    track_points$ogc_fid <-c(existing_rows$count+1:nrow(track_points))
  }else{
    # start <- as.integer(existing_rows_session+1)
    # end <- as.integer(existing_rows_session+nrow(track_points))
    start <- as.integer(existing_rows+1)
    end <- as.integer(existing_rows+nrow(track_points))
    track_points$ogc_fid <-c(start:end)
  }
  track_points$session_id <- session_id
  head(track_points)
  if(type=="GPX"){track_points$time <- as.POSIXct(track_points@data$time, tz="UTC")}
  class(track_points$time)
  attr(track_points$time,"tzone")
  track_points$the_geom <- NA
  
  GPS_tracks_values <- NULL
  
    if(type=="RTK"){
    select_columns = subset(track_points, select = c(ogc_fid,session_id,latitude,longitude,height,GPST,age,the_geom))
    GPS_tracks_values = dplyr::rename(select_columns, ogc_fid=ogc_fid,session_id=session_id, latitude=latitude,longitude=longitude, altitude=height, heart_rate=age, time=GPST)
    sapply(GPS_tracks_values,class)
    GPS_tracks_values$heart_rate <- c(1:nrow(GPS_tracks_values))
    GPS_tracks_values$time <- as.POSIXct(GPS_tracks_values$time, "%Y/%m/%d %H:%M:%OS")
    head(GPS_tracks_values)
    # write.csv(GPS_tracks_values, paste0(gsub(pattern = ".rtk",""_rtk.csv",gps_file)"),row.names = F)
    
  } else if(type=="GPX"){
    sapply(track_points@data,class)
    
    GPS_tracks_values <- dplyr::select(track_points@data,ogc_fid,session_id,time,ele,track_fid,the_geom) %>% mutate(latitude = track_points@coords[,2]) %>% mutate(longitude = track_points@coords[,1])
    GPS_tracks_values= dplyr::rename(GPS_tracks_values, ogc_fid=ogc_fid, session_id=session_id, time=time, latitude=latitude,longitude=longitude, altitude=ele, heart_rate=track_fid, the_geom=the_geom)
    GPS_tracks_values <- GPS_tracks_values[,c(1,2,3,7,8,4,5,6)]
    write.csv(GPS_tracks_values, gsub(".gpx","_gpx.csv",gps_file),row.names = F)
    
  } else if (type=="TCX"){
    # https://cran.r-project.org/web/packages/trackeR/vignettes/TourDetrackeR.html => duplicates are removed ?
    # select_columns = subset(track_points, select = c(ogc_fid,session_id,latitude,longitude,altitude,time,heart_rate))
    GPS_tracks_values <- dplyr::select(track_points,ogc_fid,session_id, time, latitude,longitude,altitude,heart_rate,the_geom)
    # GPS_tracks_values = dplyr::rename(GPS_tracks_values, ogc_fid=ogc_fid, session_id=session_id, time=time, latitude=latitude,longitude=longitude, altitude=altitude, heart_rate=heart_rate,the_geom=the_geom)
    write.csv(GPS_tracks_values, gsub(".tcx","_tcx.csv",gps_file),row.names = F)
  }
  
  head(GPS_tracks_values)
  if(load_in_database==TRUE){load_gps_tracks_in_database(con_database, codes_directory, GPS_tracks_values, create_table=FALSE)}
  # dbWriteSpatial(con_database, track_points, schemaname="public", tablename="pays", replace=T,srid=4326)
  
  return(GPS_tracks_values)
  
}

#############################################################################################################
############################ RETRIEVE TCX FILES ###################################################
#############################################################################################################
return_dataframe_gps_files <- function(wd,type="TCX"){
  setwd(wd)
  dataframe_gps_files <- NULL
  dataframe_gps_files <- data.frame(session=character(), path=character(), file_name=character())
  sub_directories <- list.dirs(path=wd,full.names = TRUE,recursive = TRUE)
  sub_directories  
  for (i in sub_directories){
    if (substr(i, nchar(i)-3, nchar(i))=="/GPS"){
      setwd(i)
      name_session <- gsub(paste(dirname(dirname(i)),"/",sep=""),"",dirname(i))
      cat(paste0("\n Processing GPS repository => ",i,"\n"))
      cat(paste0("\n Name session => ",name_session,"\n"))
      cat("\n List tcx files \n")
      if (type=="TCX"){pattern = "\\.tcx$"} else if (type=="GPX"){pattern = "\\.gpx$"} else if (type=="RTK"){pattern = "\\.rtk$"}
      files <- list.files(pattern = pattern,ignore.case=TRUE)
      gps_files <- files
      cat("\n Names of spatial data files \n")
      cat(gps_files)
      # if(length(gps_files)>1){cat("\n ERROR! \n")}
      # cat(c(name_session,i,gps_files))
      if(length(gps_files)>0){
        newRow <- data.frame(session=name_session,path=i,file_name=gps_files)
        dataframe_gps_files <- rbind(dataframe_gps_files,newRow)
      }else{
        dataframe_gps_files <-NULL
        }
    }
    else {
      # cat(paste("Ignored / no GPS tracks in ", i, "\n",sep=""))
      # cat("nada \n")
      # cat(substr(i, nchar(i)-2, nchar(i)))
    }
  }
  
  cat("\n End return_dataframe_gps_files function \n")
  return(dataframe_gps_files)
}

########################################################################################################################
################### Run SF to turn a CSV into a shapefile #######################
########################################################################################################################
# # https://r-spatial.github.io/sf/reference/st_as_sf.html
# setwd("/tmp/")
# file_name <-"photos_location"
# write_shp_from_csv(file_name)

write_shp_from_csv <- function(file_name){
csv_file <- paste0 (file_name,".csv")
df <- read.csv(csv_file)
plot_locations <- st_as_sf(df, coords = c("longitude", "latitude"),crs = 4326)
shape_file <- paste0 (file_name,".shp")
st_write(plot_locations, shape_file)

return(shape_file)

}

########################################################################################################################
##### Send file in google drive and get URL ##########
########################################################################################################################
# https://googledrive.tidyverse.org/
# install.packages("googledrive")    

upload_google_drive <- function(google_drive_path,media,file_name){
  google_drive_file <- drive_upload(media=media, path = google_drive_path,name=file_name)
  # If to update the content or metadata of an existing Drive file, use drive_update()
  return(google_drive_file)
}


# google_drive_path <- drive_get(id="1gUOhjNk0Ydv8PZXrRT2KQ1NE6iVy-unR")
# google_drive_file_url <- paste0("https://drive.google.com/open?id=",google_drive_path$id)

upload_file_on_drive_repository <- function(google_drive_path,media,file_name,type=NULL){
  # check <- drive_find(pattern = file_name)
  # drive_get(path = google_drive_path, id = file_name, team_drive = NULL, corpus = NULL,verbose = TRUE)
  check <- drive_ls(path = google_drive_path, pattern = file_name, recursive = FALSE)
  check
  setwd(tempdir())
  csvfile <- paste0(file_name,".csv")
  write.csv(media, csvfile,row.names = F)
  if(nrow(check)>0){
    google_drive_file <- drive_update(file=as_id(check$id[1]), name=file_name, media=csvfile)
    # google_drive_file <- drive_upload(media=file_name, path = google_drive_path,name=file_name)
    
  }else{
    google_drive_file <- drive_upload(media=csvfile, path = google_drive_path,name=file_name,type = type)
  }
  # If to update the content or metadata of an existing Drive file, use drive_update()
  google_drive_file_url <- paste0("https://drive.google.com/open?id=",google_drive_file$id)
  google_drive_file %>% drive_reveal("permissions")
  google_drive_file %>% drive_reveal("published")
  google_drive_file <- google_drive_file %>% drive_share(role = "reader", type = "anyone")
  google_drive_file %>% drive_reveal("published")
  file_id <- google_drive_file$id
  
  return(file_id)
}

# library("googledrive")
# drive_find(n_max = 30)
# drive_find(pattern = "test_metadata", type = "folder")
# drive_find(pattern = "session", type = "folder")
# file_name <-"/home/julien/Téléchargements/FAIR.pdf"
# google_drive_path <- drive_get(id="1gUOhjNk0Ydv8PZXrRT2KQ1NE6iVy-unR")
# google_drive_file <- upload_google_drive(google_drive_path,file_name)
# google_drive_file_url <- paste0("https://drive.google.com/open?id=",google_drive_file$id)
# google_drive_file_url
# google_drive_file %>% drive_reveal("permissions")
# google_drive_file %>% drive_reveal("published")
# google_drive_file <- google_drive_file %>% drive_share(role = "reader", type = "anyone")
# google_drive_file %>% drive_reveal("published")
# google_drive_file <- drive_publish(as_id(google_drive_file$id))
# drive_rm(google_drive_file)


########################################################################################################################
################### Write Qgis project #######################
########################################################################################################################
# qgs_template <- "/home/julien/Bureau/CODES/Deep_mapping/template/qgis_project_csv.qgs"

write_qgis_project <- function(session_id,qgs_template,file_path,xmin,xmax,ymin,ymax){
  
  qgis_project <- readLines(qgs_template,encoding="UTF-8")
  qgis_project <- gsub("template_file_name", file_path,qgis_project)
  qgis_project <- gsub("/path/","",qgis_project)
  qgis_project <- gsub("template_xmin",xmin,qgis_project)
  qgis_project <- gsub("template_xmax",xmax,qgis_project)
  qgis_project <- gsub("template_ymin",ymin,qgis_project)
  qgis_project <- gsub("template_ymax",ymax,qgis_project)
  
  qgis_project_file <- paste0(session_id,".qgs")
  write(qgis_project, file = qgis_project_file,ncolumns=1)
  cat("qgis project created")
  
  # return(xx)
  
} 


#############################################################################################################
############################ plot map TCX file ###################################################
#############################################################################################################
plot_tcx <- function(tcx_file,directory){
  # https://cran.r-project.org/web/packages/trackeR/vignettes/TourDetrackeR.html
  original_directory <- getwd()
  setwd(paste0(directory,"/METADATA"))
  this_session_gps_tracks <- readContainer(tcx_file, type = "tcx", timezone = "GMT")
  # plot(runTr1)
  jpeg(paste0(plot_tcx,"rplot.jpg"))
  # plotRoute(this_session_gps_tracks, zoom = 13, source = "google")
  plotRoute(this_session_gps_tracks, zoom = 13, source = "stamen")
  dev.off()
  setwd(original_directory)
}    



#############################################################################################################
############################ plot map TCX file ###################################################
#############################################################################################################
# jsonfile <- "/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/Drone_images/2019_08_10_La_Preneuse_Tamarin/Mission 1/image_locations.json"

drone_photos_locations <- function(jsonfile){
  result <- fromJSON(file = jsonfile)
  library("rjson")
  length(result)
  lengths(result)
  class(result)
  json_data_frame <-NULL
  json_data_frame <- data.frame(filename=character(),
                                aboveGroundAltitude=character(),
                                altitudeReference=character(),
                                index=integer(),
                                latitude=character(),
                                longitude=character(),
                                pitch=character(),
                                roll=character(),
                                yaw=character()
                                )
  
  for(i in 1:length(result)){
    # print(result[i])
    # print(result[[i]])
    newRow <-NULL
    newRow <-  data.frame(filename=names(result[i]),
                           aboveGroundAltitude=result[[i]]$aboveGroundAltitude,
                           altitudeReference=result[[i]]$altitudeReference,
                           index=result[[i]]$index,
                           latitude=result[[i]]$location2D$latitude,
                           longitude=result[[i]]$location2D$longitude,
                           pitch=result[[i]]$pitch,
                           roll=result[[i]]$roll,
                           yaw=result[[i]]$yaw
    )
    json_data_frame <- rbind(json_data_frame,newRow)
    
  }
  json_data_frame
  # write.csv(json_data_frame, paste("/tmp/drones.csv", sep=""),row.names = F)
  return(json_data_frame)
}





#############################################################################################################
############################ return a dataframe with all tags for multiple sessions  ########################
#############################################################################################################

# Function to merge the annotations of images coming from different files (one per session / survey)
return_dataframe_tag_txt <- function(wd,all_categories){
  
  tmpdir <- tempdir()
  dataframe_csv_files <- NULL
  dataframe_csv_files <- data.frame(session=character(), path=character(), file_name=character,photo_name=character)
  sub_directories <- list.dirs(path=wd,full.names = TRUE,recursive = TRUE)
  sub_directories <- data.frame(full_path=list.dirs(path=wd,full.names = TRUE,recursive = TRUE)) %>% filter(endsWith(x = full_path, suffix = "LABEL"))
  sub_directories
  
  for (i in sub_directories$full_path){
      setwd(i)
      path_session <-dirname(i)
      cat(paste0(path_session,"\n"))
      name_session <-gsub(paste(dirname(path_session),"/",sep=""),"",path_session)
      files <- list.files(pattern = "\\.txt$")
      # if(length(files)==1){
      if(length(files)>0){
        csv_files <- files
        newRow <- data.frame(session=name_session,path=i,file_name=csv_files)
        dataframe_csv_files <- rbind(dataframe_csv_files,newRow)
        for (f in files){
          csv_file <-NULL
          fileName <-  paste0(tmpdir,"/",name_session,"_",gsub(".txt",".csv",f))
          #copy tag.txt file as "session_id_tag.csv" file
          system(paste0("cp ",paste0(i,"/",f)," ", fileName))
          #add the header to newly created csv file
          system(paste0("sed -i '1 i\\","path;tag'"," ",fileName))
          #set of cleaning actions
          tx2  <- readChar(fileName, file.info(fileName)$size)
          tx2  <- gsub(pattern = "[\r\n]+", replace = "\n", x = tx2)
          tx2  <- gsub(pattern = "[  ]+", replace = " ", x = tx2)
          tx2  <- gsub(pattern = "[   ]+", replace = " ", x = tx2)
          tx2  <- gsub(pattern = ",", replace = " et ", x = tx2)
          tx2  <- gsub(pattern = " => ", replace = ";", x = tx2)
          tx2  <- gsub(pattern = ";", replace = ",", x = tx2)
          tx2  <- gsub(pattern = "herbier marron", replace = "Thalassodendron ciliatum", x = tx2)
          tx2  <- gsub(pattern = "herbier vert", replace = "Syringodium isoetifolium", x = tx2)
          tx2  <- gsub(pattern = "algue marron", replace = "Sargassum ilicifolium", x = tx2)
          tx2  <- gsub(pattern = "algues marron", replace = "Sargassum ilicifolium", x = tx2)
          tx2  <- gsub(pattern = "algue pourrie", replace = "Turbinaria ornata", x = tx2)
          tx2  <- gsub(pattern = "algues pourrie", replace = "Turbinaria ornata", x = tx2)
          tx2  <- gsub(pattern = "holoturie noire", replace = "Stichopus chloronotus", x = tx2)
          tx2  <- gsub(pattern = "holoturies", replace = "Holoturian", x = tx2)
          tx2  <- gsub(pattern = "holoturie", replace = "Holoturian", x = tx2)
          tx2  <- gsub(pattern = "idole des maures", replace = "Zanclus cornutus", x = tx2)
          tx2  <- gsub(pattern = "coraux", replace = "coral", x = tx2)
          tx2  <- gsub(pattern = "corail", replace = "coral", x = tx2)
          tx2  <- gsub(pattern = "corail de feu", replace = "Millepora", x = tx2)
          tx2  <- gsub(pattern = "sable", replace = "sand", x = tx2)
          tx2  <- gsub(pattern = "poisson", replace = "fish", x = tx2)
          # tx2  <- gsub(pattern = '.*\\/DCIM', replace = paste0(path,"/DCIM"),x = tx2)
          
          # for(dir in 1:nrow(all_categories)){
          #   # print(paste0("Trying to detect",all_categories$Pattern[dir],"\n"))
          #   tx2 <- gsub(pattern =all_categories$Pattern[dir], replace = all_categories$SubName[dir], x = tx2)
          # }
          # write the temp file
          fileName_bis <-  gsub(pattern = ".csv", replace = "_bis.csv", x = fileName)
          writeLines(tx2, con=fileName_bis)
          
          fileName_ter <-  gsub(pattern = ".csv", replace = "_ter.csv", x = fileName)
          # csv_file <- readLines(con <- file(fileName_bis))
          csv_file <- read.csv(fileName_bis,sep = ",")
          csv_file$path <- gsub(pattern = '.*\\/DCIM', replace = paste0(path_session,"/DCIM"),x = csv_file$path)
          csv_file$name_session <- gsub("/","",name_session)
          csv_file$file_name <-gsub(pattern = '.*\\/G0',"G0",csv_file$path)
          csv_file$photo_name=paste0(csv_file$name_session,"_",csv_file$file_name)

          # writeLines(csv_file,con=fileName_ter)
          write.table(x = csv_file,file = fileName_ter, sep=",",row.names = FALSE)
          # system(paste0("rm ",fileName))
          # system(paste0("rm ",fileName_bis))
        }
      } else {
        cat("\ These repositories CHECK\n")
        cat(i)
        cat("\n")
      }
  }
  
  setwd(tmpdir)
  files <- list.files(pattern = "*ter.csv")
  all_files <- NULL
  all_files <- Reduce(rbind, lapply(files, read.csv))
  
  # Command below might also be used
  # system(command = "awk 'FNR==1 && NR!=1{next;}{print}' *ter.csv  > all_files_combined.csv")
  file_name <-"all_files_combined.csv"
  write.table(x = all_files,file = file_name, sep=",",row.names = FALSE)
  
  return(all_files)
}

########################################################################################################################################################
############################ copy all annotated images in  repositories whose name are the same as the label annotating images  ########################
########################################################################################################################################################
# Function to copy all annotated images in a single repository and/or in repositories whose name is the same as the label annotating images

copy_images_for_training <- function(wd_copy, all_images,file_categories,crop_images=FALSE){
  current_dir <- getwd()
  setwd(wd_copy)
  # create sub-repositories for  each object / category to be identified where all images tagged with this category will be copied
  file_categories <- file_categories  %>%  select(SubName,TagName) %>% distinct()
  for(dir in 1:nrow(file_categories)){
    #we filter the dataset to selectonly images tagged with the category (matching the pattern)
    mainDir <-  file_categories$TagName[dir]
    print(paste0("Trying to detect",file_categories$Pattern[dir],"\n"))
    relevant_images <- all_images %>% filter(str_detect(tag, file_categories$SubName[dir]))
    # if some images have been tagged with the relevant label we create the sub-reporsitory with the name of the label
    if(nrow(relevant_images)>0){
      dir.create(mainDir)
      setwd(mainDir)
      if(crop_images){dir.create(file.path(mainDir, "crop"))}
      # we copy each image in the sub-repository and in wd_copy as well if needed
      for(f in 1:nrow(relevant_images)){
        # print(paste0("\n",relevant_images$path[f]),"\n")
        # check the clause below!
        if(length(relevant_images$path[f])>0){
          # copy relevant images for this category in this sub-repository (crop images if asked)
          filename <- gsub(paste0(dirname(as.character(relevant_images$path[f])),"/"),"", as.character(relevant_images$path[f]))
          # print(paste0(filename,"\n"))
          command <- paste0("cp ", as.character(relevant_images$path[f])," ./",relevant_images$photo_name[f],"\n")
          print(command)
          # cat(paste0("cp ",paste0(as.character(relevant_images$path[f])," .",gsub(dirname(as.character(relevant_images$path[f])),"", as.character(relevant_images$path[f]))),"\n"))
          # if(!file.exists(relevant_images$photo_name[f])){
          system(command)
          # }
          # system(gsub(" ."," ..",command))
        }else{
          cat(paste0("\n issue with ",relevant_images$path[f],"\n" ))
        }
        if(crop_images){crop_this_image(filename,mainDir)}
      }
    }
    setwd(wd_copy)
  }
  cat("done")
  setwd(current_dir)
}


#############################################################################################################
############################ infer_photo_location_from_gps_tracks ###################################################
#############################################################################################################
# Create or replace a SQL materialized view to gather data per dataset / survey

create_view_species_occurences <- function(con_database,codes_directory,images_directory){
  original_directory <- getwd()
  setwd(images_directory)
  query <- NULL
  query <- paste(readLines(paste0(codes_directory,"SQL/extract_species_occurences_manual_annotation.sql")), collapse=" ")
  query_drop <- paste0('DROP MATERIALIZED VIEW IF EXISTS "view_occurences_manual_annotation";')
  query <- paste0(query_drop,'CREATE MATERIALIZED VIEW "view_occurences_manual_annotation" AS ',query)
  query <- paste0(query," WITH DATA")
  dbGetQuery(con_database, query)
  add_spatial_index <- dbGetQuery(con_database, paste0('DROP INDEX IF EXISTS \"view_occurences_manual_annotation_geom_idx\" ;  CREATE INDEX \"view_occurences_manual_annotation_geom_idx\" ON \"view_occurences_manual_annotation\" USING GIST (geometry_postgis);'))
  create_csv_from_view <- dbGetQuery(con_database, paste0('SELECT * FROM \"view_occurences_manual_annotation\";'))
  setwd(images_directory)
  filename <- "view_occurences_manual_annotation.csv"
  write.csv(create_csv_from_view, filename,row.names = F)
  # shape_file <- write_shp_from_csv(file_name)
  setwd(original_directory)
  # return(create_csv_from_view)
}

#############################################################################################################
############################ update inferred geometry ###################################################
#############################################################################################################
# Create or replace a SQL materialized view to gather data per dataset / survey

update_inferred_geometry <- function(con_database,codes_directory,images_directory){
  original_directory <- getwd()
  setwd(images_directory)
  query_sessions <-   dbGetQuery(con_database, 'SELECT DISTINCT session_id from public."photos_exif_core_metadata" ORDER BY session_id ASC')
  for(i in 1:nrow(query_sessions)){
    query <- NULL
    query <- paste(readLines(paste0(codes_directory,"SQL/update_gps_geometry_colum.sql")), collapse=" ")
    query <- gsub("session_2018_01_14_kite_Le_Morne",query_sessions$session_id[i],query)
    print(paste0(query,"\n"))
    dbGetQuery(con_database, query)
    
  }
  setwd(original_directory)
}

##########################################################################################################################################################################################################################
######################### extract pictures by WKT area and copy them in a temp folder to foster annation ###############################################
##########################################################################################################################################################################################################################
spatial_extraction_of_pictures_and_copy_in_tmp_folder<- function(wd, con_database,codes_directory=codes_directory,images_directory,wkt,expected_species){
  
  setwd(wd)
  
  #write query to extract all pictures within the given wkt / spatial area
  query <- NULL
  query <- paste(readLines(paste0(codes_directory,"SQL/select_pictures_by_area.sql")), collapse=" ")
  # query <- "SELECT photo_path,session_id,\"FileName\",photo_name,photo_id,map_photo_id FROM public.species_within_buffer;"
  if(wkt=='none'){
    query <- gsub("WHERE","--WHERE",query)
  }else{
    query <- gsub("polygon_wkt",wkt,query)
  }
  print(paste0(query,"\n"))
  
  #execute query
  extracted_images <- dbGetQuery(con_database, query)
  nrow(extracted_images)
  
  #remove pictures already annotated
  extracted_images_already_annotated <- extracted_images %>% filter(!is.na(map_photo_id))
  nrow(extracted_images_already_annotated)
  extracted_images_not_annotated <- extracted_images %>% filter(is.na(map_photo_id))
  nrow(extracted_images_not_annotated)
  # ratio <- nrow(extracted_images_already_annotated)/nrow(extracted_images)
  # ratio
  
  #copy pictures not annotated within the temp file
  if(wkt!='none'){
    for(i in 1:nrow(extracted_images_not_annotated)){
    filename <- paste0(images_directory,extracted_images_not_annotated$photo_path[i])
    command <- paste0("cp ", filename,"  ",getwd(),"/",extracted_images_not_annotated$photo_name[i],"\n")
    cat(command)
    system(command)
    }
  }
  return(extracted_images_not_annotated)
}

#############################################################################################################
#############################################################################################################
turn_list_of_files_into_csv_annotated<- function(con_database,wd_selected_candidates,extracted_images_not_annotated,expected_species, mime_type = "*.JPG"){
  
  # labels <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1mBQiokVvVwz3ofDGwQFKr3Q4EGnn8nSrA1MEzaFIOpc/edit?usp=sharing"))
  query_labels <- paste0('SELECT * FROM public.label where tag_label=\'',expected_species,'\' ;')
  label <- dbGetQuery(con_database, query_labels)
  
  setwd(wd_selected_candidates)
  files <- list.files(pattern = mime_type ,recursive = TRUE)
  vector <- as.vector(files)
  df <- as.data.frame(vector) %>% rename(photo_name = vector)  %>% mutate(tag = expected_species,tag_id=label$tag_id)
  nrow(df)
  colnames(df)
  colnames(extracted_images_not_annotated)
  csv_tags <-NULL
  # csv_tags <- left_join(df,extracted_images_not_annotated,by = "photo_name") %>% distinct()
  csv_tags <- left_join(df,extracted_images_not_annotated,by = "photo_name")  %>% filter(is.na(map_photo_id)) %>% filter(!is.na(photo_id))  %>% relocate(photo_path,session_id,FileName,tag,photo_name,photo_id,map_photo_id) %>% rename(path=photo_path,name_session=session_id,file_name=FileName,tag=tag) %>% distinct() 
  colnames(csv_tags)
  nrow(csv_tags)
  expected_species <- gsub(" ","_", expected_species)
  name_file_csv<-paste("candidates_",expected_species,".csv",sep="")
  write.csv(csv_tags, name_file_csv,row.names = F)
  
  # for(i in 1:nrow(csv_tags)){
  #   filename <- paste0(images_directory,csv_tags$path[i])
  #   command <- paste0("cp ", filename,"  ",getwd(),"/",csv_tags$photo_name[i],"\n")
  #   cat(command)
  #   system(command)
  # }
  query_annotation <-" "
  if(nrow(csv_tags)>=1){
    for(r in 1:nrow(csv_tags)){
      # cat(paste0("\n The label ",labels$tag_label[l]," has been found in annotation of picture: ",relevant_images$photo_name[r],"\n"))
      query_annotation_line <- paste0('INSERT INTO annotation VALUES (\'',csv_tags$photo_id[r],'\',\'',label$tag_id,'\');')
      query_annotation <- paste0(query_annotation_line,"\n",query_annotation)
      
    }
  }
  
  fileConn<-file(paste0('query_annotation.SQL'))
  writeLines(query_annotation, fileConn)
  close(fileConn)
  relevant_images <- dbGetQuery(con_database, query_annotation)
  
  # dbGetQuery(con_database, query_annotation)
  return(query_annotation)
}

#############################################################################################################
#############################################################################################################
##########################################################################################################################################################################################################################
######################### extract pictures by WKT area and copy them in a temp folder to foster annation ###############################################
##########################################################################################################################################################################################################################
extraction_annotated_pictures_from_db<- function(con_database,codes_directory,images_directory){
  
  query <- NULL
  query <- paste(readLines(paste0(codes_directory,"SQL/select_annotated_pictures.sql")), collapse=" ")
  #execute query
  extracted_images <- dbGetQuery(con_database, query)
  nrow(extracted_images)
  list_sessions <- extracted_images %>% select(name_session) %>% distinct()
  directories <- NULL
  directories <-data.frame(full_path=list.dirs(path=c("/media/julien/Storage_SSD/Data_Deep_Mapping","/home/julien/Desktop/Data/Data_Deep_Mapping"),full.names = TRUE, recursive = TRUE))
  for(n in 1:nrow(list_sessions)){
    full_path_directory<- directories  %>% filter(endsWith(x = full_path, suffix = list_sessions$name_session[n]))
    list_sessions$prefix_path[n] <- gsub(paste0(paste0("/",list_sessions$name_session[n])),"",full_path_directory)
  }
  list_sessions
  extracted_images <- left_join(extracted_images, list_sessions,by = "name_session")  %>% mutate(path = paste0(prefix_path,relative_path,"/",file_name))  %>% select(path,tag,name_session,file_name,photo_name)
  head(extracted_images)
  
  training_images <- "/tmp/training_dataset"
  all_categories <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1mBQiokVvVwz3ofDGwQFKr3Q4EGnn8nSrA1MEzaFIOpc/edit?usp=sharing"))
  copy_images_for_training(wd_copy=training_images, extracted_images,all_categories,crop_images=FALSE)
  
  return(extracted_images)
  

  
}



publish_annotated_photos_in_gsheet<- function(con_database, google_drive_path){
  query <- NULL
  query <- paste(readLines(paste0(codes_directory,"SQL/select_annotated_images_attributes.sql")), collapse=" ")
  extracted_images <- dbGetQuery(con_database, query)
  file_name <-"annotated_images_in_database"
  metadata_gsheet_id <- upload_file_on_drive_repository(google_drive_path,media=extracted_images, file_name=file_name,type="spreadsheet")
  return(metadata_gsheet_id)
  
}

# copy_images_for_test <- function(wd_copy){
#   if(nrow(relevant_images)>0){
#     dir.create(mainDir)
#     setwd(mainDir)
#     for(f in 1:nrow(relevant_images)){
#       if(length(relevant_images$path[f])>0){
#         filename <- gsub(paste0(dirname(as.character(relevant_images$path[f])),"/"),"", as.character(relevant_images$path[f]))
#         command <- paste0("cp ", as.character(relevant_images$path[f])," ./",relevant_images$photo_name[f],"\n")
#         print(command)
#         system(command)
#       }else{
#         cat(paste0("\n issue with ",relevant_images$path[f],"\n" ))
#       }
#       if(crop_images){crop_this_image(filename,mainDir)}
#     }
#   }
# }