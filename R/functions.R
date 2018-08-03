#############################################################################################################
############################ LOAD PACKAGES ###################################################
########################################################################################################
library(exifr)
library(RPostgreSQL)
library(data.table)
library(dplyr)
library(trackeR)
#############################################################################################################
###################################### LOAD SESSION METADATA ############################################################
#############################################################################################################
sessions_metadata_dataframe <- function(Dublin_Core_metadata){
  all_metadata <- NULL
  
  number_row<-nrow(Dublin_Core_metadata)
  for (i in 1:number_row) {
    # metadata <- Dublin_Core_metadata[i,]
    metadata <- NULL
    
    metadata$id_session  <- Dublin_Core_metadata$Identifier[i]# if(is.na(metadata$Identifier)){metadata$Identifier="TITLE AND DATASET NAME TO BE FILLED !!"}
    metadata$persistent_identifier <- Dublin_Core_metadata$Identifier[i]
    metadata$related_sql_query <- "SELECT TOTO..;"
    metadata$related_view_name <- paste("view_", Dublin_Core_metadata$Identifier[i], sep="")
    metadata$identifier <- Dublin_Core_metadata$Identifier[i]
    metadata$title  <- Dublin_Core_metadata$Title[i]
    metadata$contacts_and_roles  <- Dublin_Core_metadata$Creator[i]
    metadata$subject  <- Dublin_Core_metadata$Subject[i]
    metadata$description <- Dublin_Core_metadata$Description[i]
    metadata$date  <- Dublin_Core_metadata$Date[i]
    metadata$dataset_type  <- Dublin_Core_metadata$Type[i]
    metadata$format  <- Dublin_Core_metadata$Format[i]
    metadata$language  <- Dublin_Core_metadata$Language[i] #resource_language <- "eng"
    metadata$relation  <- NA
    metadata$spatial_coverage  <-  Dublin_Core_metadata$Spatial_Coverage[i]
    metadata$temporal_coverage  <-  Dublin_Core_metadata$Temporal_Coverage[i]
    metadata$rights  <- Dublin_Core_metadata$Rights[i] #UseLimitation <- "intellectualPropertyRights"
    metadata$source  <- "TO BE DONE"
    metadata$provenance  <- Dublin_Core_metadata$Lineage[i]
    metadata$supplemental_information  <- "TO BE DONE"
    metadata$database_table_name  <- "TABLE NAME"
    metadata$time_offset = Dublin_Core_metadata$Offset[i]
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
    #     GPS_tcx_file  # runDF <- readTCX(file=file, timezone = "GMT")
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
    
    
    # select_columns = subset(runDF, select = c(session,latitude,longitude,altitude,time,heart.rate))
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
############################ RETRIEVE TCX FILES ###################################################
#############################################################################################################
return_dataframe_tcx_files <- function(wd){
  setwd(wd)
  dataframe_tcx_files <- NULL
  dataframe_tcx_files <- data.frame(session=character(), path=character(), file_name=character())
  sub_directories <- list.dirs(path=wd,full.names = TRUE,recursive = TRUE)
  sub_directories  
  for (i in sub_directories){
    if (substr(i, nchar(i)-3, nchar(i))=="/GPS"){
      setwd(i)
      cat(i)
      cat("\n Name session\n")
      name_session <-gsub(paste(dirname(dirname(i)),"/",sep=""),"",dirname(i))
      cat(name_session)
      cat("\n List tcx \n")
      files <- list.files(pattern = "*.tcx")
      tcx_files <- files
      cat(tcx_files)
      if(length(tcx_files)>1){cat("\n FUCK \n")}
      cat("\n Le vecteur \n")
      cat(c(name_session,i,tcx_files))
      newRow <- data.frame(session=name_session,path=i,file_name=tcx_files)
      dataframe_tcx_files <- rbind(dataframe_tcx_files,newRow)
    }
    else {
      # cat(paste("Ignored / no GPS tracks in ", i, "\n",sep=""))
      # cat("nada \n")
      # cat(substr(i, nchar(i)-2, nchar(i)))
    }
  }
  return(dataframe_tcx_files)
}
#############################################################################################################
############################ WRITE EXIF METADATA CSV FILES ###################################################
#############################################################################################################
extract_exif_metadata_in_csv <- function(images_directory,load_metadata_in_database=FALSE){
  setwd(images_directory)
  dir.create(file.path(images_directory, "METADATA"))
  setwd(file.path(images_directory, "METADATA"))
  dir.create(file.path(getwd(), "exif"))
  metadata_directory <- file.path(getwd(), "exif")
  setwd(images_directory)
  sub_directories <- list.dirs(path=getwd(),full.names = TRUE, recursive = TRUE)
  number_sub_directories <-length(sub_directories)
  CSV_total <-NULL
  
  for (i in 1:number_sub_directories){
    # dat <-template_df
    metadata_pictures <-NULL
    setwd(images_directory)
    this_directory <- sub_directories[i]
    
    if (grepl("GOPRO",this_directory)==TRUE & grepl("not_",this_directory)==FALSE & grepl("GPS",this_directory)==FALSE & grepl("done",this_directory)==FALSE){
      # this_directory <- "/media/usb0/data_deep_mapping/good_stuff/session_2017_12_09_kite_Bel_Ombre/DCIM/142GOPRO"
      # this_directory <-  "/media/julien/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/gopro2/session_2018_03_03_kite_Pointe_Esny"
      setwd(this_directory)
      
      log <- paste("Adding references for photos in ", this_directory, "\n", sep=" ")
      # cat(log)
      parent_directory <- gsub(dirname(dirname(dirname(this_directory))),"",dirname(dirname(this_directory)))
      parent_directory <- gsub("/","",parent_directory)
      
      files <- list.files(pattern = "*.JPG",recursive = TRUE)
      exif_metadata <-template_df
      exif_metadata <- read_exif(files)
      exif_metadata$session_id = parent_directory
      exif_metadata$session_photo_number <-c(1:nrow(exif_metadata))# @julien => A INCREMENTER ?
      exif_metadata$relative_path = gsub(dirname(images_directory),"",this_directory)
      
      # # IF THERE IS NO GPS DATA WE ADD EXPECTED COLUMNS WITH DEFAULT VALUES NA
      if(exists("exif_metadata$GPSLatitude")==FALSE){ # TO BE DONE => CHECK THIS CRITERIA / TOO PERMISIVE
        exif_metadata$GPSVersionID <-NA
        exif_metadata$GPSLatitudeRef <-NA
        exif_metadata$GPSLongitudeRef <-NA
        exif_metadata$GPSAltitudeRef <-NA
        exif_metadata$GPSTimeStamp <-NA
        exif_metadata$GPSMapDatum <-NA
        exif_metadata$GPSDateStamp <-NA
        exif_metadata$GPSAltitude <-NA
        exif_metadata$GPSDateTime <-NA
        exif_metadata$GPSLatitude <-NA
        exif_metadata$GPSLongitude <-NA
        exif_metadata$GPSPosition <-NA
      }
      # change default data types
      exif_metadata$GPSDateTime = as.POSIXct(unlist(exif_metadata$GPSDateTime),"%Y:%m:%d %H:%M:%S", tz="UTC")
      exif_metadata$DateTimeOriginal = as.POSIXct(unlist(exif_metadata$DateTimeOriginal),"%Y:%m:%d %H:%M:%S", tz="Indian/Mauritius")
      exif_metadata$GPSLatitude = as.numeric(exif_metadata$GPSLatitude)
      exif_metadata$GPSLongitude = as.numeric(exif_metadata$GPSLongitude)
      exif_metadata$geometry_postgis <- NA
      exif_metadata$geometry_postgis = as.numeric(unlist(exif_metadata$geometry_postgis))
      exif_metadata$geometry_gps_correlate <- NA
      exif_metadata$geometry_gps_correlate = as.numeric(unlist(exif_metadata$geometry_gps_correlate))
      exif_metadata$geometry_native <- NA
      exif_metadata$geometry_native = as.numeric(unlist(exif_metadata$geometry_native))
      
      # sapply(dat,class)
      # new_exif_metadata <- merge(template_df,dat,by.x="SourceFile",by.y="SourceFile", all.y=TRUE,sort = F)
      # new_exif_metadata <- rbind(template_df, dat)
      new_exif_metadata <- bind_rows(template_df, exif_metadata)
      
      # new_exif_metadata <- full_join(template_df, dat)
      # m = similar(dat, 0) 
      
      # Ajouter le path de la photo ou this_directory
      # metadata_pictures <- merge(c(this_directory),metadata_pictures))
      # metadata_pictures$path <- this_directory
      # metadata_pictures$parent_directory <- parent_directory
      
      CSV_total <- rbind(CSV_total, new_exif_metadata)
      
      message_done <- paste("References for photos in ", this_directory, " are extracted !\n", sep=" ")
      cat(message_done)
      
      setwd(metadata_directory)
      # csv_file_name <- paste("all_exif_metadata_in_",this_directory,".csv",sep="")
      # write.csv(dat, csv_file_name,row.names = F)
      
      #############################################################################################################    
      #############################################MERGE WITH TAGS##############################################   
      # left_join()
      # references.csv
      #############################################################################################################    
    } else { cat(paste("Ignored / pas de photos in ", this_directory, "\n",sep=""))}
  }
  
  setwd(metadata_directory)
  name_file_csv<-paste("All_Exif_metadata_",parent_directory,".csv",sep="")
  # write.csv(CSV_total, name_file_csv,row.names = F)
  saveRDS(CSV_total, paste("All_Exif_metadata_",parent_directory,".RDS",sep=""))
  
  # add condition exists before susbet ?
  metadata_pictures <- select(CSV_total,
                              session_id,
                              session_photo_number,
                              relative_path,
                              FileName,
                              GPSLatitude,
                              GPSLongitude,
                              GPSDateTime,
                              DateTimeOriginal,
                              LightValue,
                              ImageSize,
                              Model,
                              geometry_postgis,
                              geometry_gps_correlate,
                              geometry_native                              
                              )
  
  
  name_file_csv<-paste("Core_Exif_metadata_",parent_directory,".csv",sep="")
  # write.csv(metadata_pictures, name_file_csv,row.names = F)
  saveRDS(metadata_pictures, paste("Core_Exif_metadata_",parent_directory,".RDS",sep=""))
  
  # return(nrow(read.csv("Core_Exif_metadata.csv")))
  return(head(metadata_pictures))
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