# library(data.table)
library(exifr)
library(dplyr)

#############################################################################################################
############################ WRITE EXIF METADATA CSV FILES ###################################################
#############################################################################################################
extract_exif_metadata_in_csv <- function(images_directory){
  setwd(images_directory)
  system("mkdir exif")
  metadata_directory <- paste(images_directory,"/exif/",sep="")
  sub_directories <- list.dirs(path='./',full.names = TRUE,recursive = TRUE)
  number_sub_directories <-length(sub_directories)
  CSV_total <-NULL
  # directories_level1 <- list.dirs(full.names = TRUE,recursive = FALSE)
  # directories_level1 <- strsplit(directories_level1, "/")
  
  for (i in 1:number_sub_directories){
    dat <-NULL
    metadata_pictures <-NULL
    setwd(images_directory)
    this_directory <- sub_directories[i]
    # this_directory <- "/media/julien/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/gopro2/session_2018_03_03_kite_Pointe_Esny/DCIM/177GOPRO/"
    
    if (grepl("GOPRO",this_directory)==TRUE & grepl("not_",this_directory)==FALSE & grepl("GIS",this_directory)==FALSE){
      setwd(this_directory)
      
      log <- paste("Adding references for photos in ", this_directory, "\n", sep=" ")
      # cat(log)
      this_directory <- gsub(".//","",this_directory)
      remove <-substr(this_directory, nchar(this_directory)-8, nchar(this_directory))
      parent_directory <- gsub(remove,"",this_directory)
      parent_directory <- gsub("/DCIM","",parent_directory)
      # this_directory <- gsub("/","_",this_directory)  
      files <- list.files(pattern = "*.JPG")
      dat <- read_exif(files)
      # IF THERE IS NO GPS DATA WE ADD EXPECTED COLUMNS WITH DEFAULT VALUES NA
      if(is.null(dat$GPSLatitude)){ # TO BE DONE => CHECK THIS CRITERIA / TOO PERMISIVE
        dat$GPSLatitudeRef <-NA
        dat$GPSLongitudeRef <-NA
        dat$GPSAltitudeRef <-NA
        dat$GPSTimeStamp <-NA
        dat$GPSDateStamp <-NA
        dat$GPSAltitude <-NA
        dat$GPSDateTime <-NA
        dat$GPSLatitude <-NA
        dat$GPSLongitude <-NA
        dat$GPSPosition <-NA
      }
      # Ajouter le path de la photo ou this_directory
      # metadata_pictures <- merge(c(this_directory),metadata_pictures))
      # metadata_pictures$path <- this_directory
      # metadata_pictures$parent_directory <- parent_directory
      CSV_total <- rbind(CSV_total, dat)
      
      # CSV_total$ThumbnailImage[1]
      # CSV_total$ThumbnailOffset[1]
      # CSV_total$ThumbnailLength[1]
      
      
      message_done <- paste("References for photos in ", this_directory, " are extracted !\n", sep=" ")
      cat(message_done)
      
      setwd(metadata_directory)
      csv_file_name <- paste("all_exif_metadata_in_",this_directory,".csv",sep="")
      write.csv(dat, csv_file_name,row.names = F)
      
      #############################################################################################################    
      #############################################MERGE WITH TAGS##############################################   
      # left_join()
      # references.csv
      #############################################################################################################    
    } else { cat(paste("Ignored / pas de photos in ", this_directory, "\n",sep=""))}
  }
  
  setwd(metadata_directory)
  write.csv(CSV_total, "All_Exif_metadata.csv",row.names = F)
  
  metadata_pictures <- select(CSV_total,
                              FileName,
                              GPSLatitude,
                              GPSLongitude,
                              GPSDateTime,
                              DateTimeOriginal,
                              LightValue,
                              ImageSize,
                              Model)
  
  write.csv(metadata_pictures, "Core_Exif_metadata.csv",row.names = F)
  
  return(nrow(read.csv("Core_Exif_metadata.csv")))
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
      name_session <-gsub(paste(dirname(dirname(i)),"/",sep=""),"",dirname(i))
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
current_wd<-getwd()
directory <- "/media/julien/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/gopro2"
dataframe_tcx_files <- return_dataframe_tcx_files(directory)
dataframe_csv_files <- return_dataframe_csv_exif_metadata_files(directory)
setwd(current_wd)

#################################################################################################################################################
################################### LOAD POSTGIS DATABASE WITH EXIF METADATA AND GPS TRACKS DATA ################################################
#################################################################################################################################################

###########################################################################################################################
library(RPostgreSQL)
# library(data.table)
library(dplyr)
source("/home/julien/Bureau/CODES/Deep_mapping/R/credentials_postgres.R")
con_Reef_database <- dbConnect(DRV, user=User, password=Password, dbname=Dbname, host=Host)
###################################### LOAD GPS TRACKS DATA ############################################################


query_create_table <- paste(readLines("/home/julien/Bureau/CODES/Deep_Mapping/SQL/create_tables_GPS_tracks.sql"), collapse=" ")
query_update_table_spatial_column <- paste(readLines("/home/julien/Bureau/CODES/Deep_Mapping/SQL/add_spatial_column.sql"), collapse=" ")
create_Table <- dbGetQuery(con_Reef_database,query_create_table)
# dbWriteTable(con_Reef_database, "gps_tracks", GPS_tracks_values, row.names=FALSE, append=TRUE)
dataframe_list_tcx_files <- return_dataframe_tcx_files(wd)

number_row<-nrow(dataframe_tcx_files)
for (t in 1:number_row){
  row <- dataframe_tcx_files[t,]
  session <- dataframe_tcx_files$session[t]
  path <- dataframe_tcx_files$path[t]
  file_name <- dataframe_tcx_files$file_name[t]
  file = paste(path,file_name,sep="/")
  runDF <- NULL
#   # runDF <- readTCX(file=file, timezone = "GMT")
  runDF <- readTCX(file=file)
  runDF$session <- session
  select_columns = subset(runDF, select = c(session,latitude,longitude,altitude,time,heart.rate))
  GPS_tracks_values = rename(select_columns, session_id=session, latitude=latitude,longitude=longitude, altitude=altitude, heart_rate=heart.rate, time=time)
  names(GPS_tracks_values)
  # GPS_tracks_values$fid <-c(1:nrow(GPS_tracks_values))
  # GPS_tracks_values <- GPS_tracks_values[,c(6,1,2,3,4,5)]
  # GPS_tracks_values$time <- as.POSIXct(GPS_tracks_values$time, "%Y-%m-%d %H:%M:%OS")
  GPS_tracks_values$the_geom <- NA
  dbWriteTable(con_Reef_database, "gps_tracks", GPS_tracks_values, row.names=TRUE, append=TRUE)
}

update_Table <- dbGetQuery(con_Reef_database,query_update_table_spatial_column)

###################################### LOAD PHOTOS EXIF CORE METADATA ############################################################
query_create_exif_core_metadata_table <- paste(readLines("/home/julien/Bureau/CODES/Deep_mapping/SQL/create_exif_core_metadata_table.sql"), collapse=" ")
create__exif_core_metadata_table <- dbGetQuery(con_Reef_database,query_create_exif_core_metadata_table)

current_wd<-getwd()
directory <- "/media/julien/ab29186c-4812-4fa3-bf4d-583f3f5ce311/julien/gopro2"
dataframe_csv_files <- return_dataframe_csv_exif_metadata_files(directory)


setwd(current_wd)

number_row<-nrow(dataframe_csv_files)
for (All_Exif_metadata.csv in 1:dataframe_csv_files){
  row <- dataframe_csv_files[csv,]
  session <- dataframe_csv_files$session[csv]
  path <- dataframe_csv_files$path[csv]
  file_name <- dataframe_csv_files$file_name[csv]
  if(file_name=="All_Exif_metadata.csv"){
    cat("\n GOTCHA \n")
    file = paste(path,file_name,sep="/")
    CSV_total <- NULL
    csv_data_frame <- NULL
    CSV_total <- read.csv(file=file)
    metadata_pictures <- select(CSV_total,
                                FileName,
                                GPSLatitude,
                                GPSLongitude,
                                GPSDateTime,
                                DateTimeOriginal,
                                LightValue,
                                ImageSize,
                                Model)
    metadata_pictures$session <- session
    metadata_pictures$geometry_postgis <- NA
    metadata_pictures$geometry_gps_correlate <- NA
    metadata_pictures$geometry_native <- NA
    csv_data_frame = rename(metadata_pictures, session_id=session, filename=FileName, gpslatitud=GPSLatitude, gpslongitu=GPSLongitude, gpsdatetim=GPSDateTime, datetimeor=DateTimeOriginal, lightvalue=LightValue, imagesize=ImageSize, model=Model)
    names(csv_data_frame)
    dbWriteTable(con_Reef_database, "photos_exif_core_metadata", csv_data_frame, row.names=TRUE, append=TRUE)
  }

}

update_Table <- dbGetQuery(con_Reef_database,query_update_table_spatial_column)

###################################### LOAD PHOTOS EXIF CORE METADATA ############################################################

dbDisconnect(con_Reef_database)


