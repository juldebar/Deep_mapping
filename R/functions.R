#############################################################################################################
############################ LOAD PACKAGES ###################################################
########################################################################################################
library(exifr)
library(RPostgreSQL)
library(rgdal)
library(data.table)
library(dplyr)
library(trackeR)
#############################################################################################################
###################################### Calculate offset ############################################################
#############################################################################################################
return_offset <- function(con, session_metadata){
  
  photo_time <- as.POSIXct(session_metadata$Photo_time)
  GPS_time <- as.POSIXct(session_metadata$GPS_time, tz="UTC")
  photo_time_database <- dbGetQuery(con, paste0("select \"DateTimeOriginal\" from photos_exif_core_metadata where \"FileName\"='",session_metadata$Photo_for_calibration,"' AND session_id='",session_metadata$Identifier,"';"))
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
############################ WRITE EXIF METADATA CSV FILES ###################################################
#############################################################################################################
extract_exif_metadata_in_csv <- function(images_directory,template_df,load_metadata_in_database=FALSE){
  setwd(images_directory)
  session_id <- gsub(paste0(dirname(images_directory),"/"),"",images_directory)
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
      # this_directory <- "/media/usb0/go_pro/backup_2To/session_2018_06_30_kite_Le_Morne/DCIM/101GOPRO"
      exif_metadata <- extract_exif_metadata_in_this_directory(images_directory,this_directory,template_df)
      # new_exif_metadata <- merge(template_df,dat,by.x="SourceFile",by.y="SourceFile", all.y=TRUE,sort = F)
      # new_exif_metadata <- rbind(template_df, dat)
      new_exif_metadata <- bind_rows(template_df, exif_metadata)
      # new_exif_metadata <- full_join(template_df, dat)
      # m = similar(dat, 0) 
      
      # Ajouter le path de la photo ou this_directory
      # metadata_pictures <- merge(c(this_directory),metadata_pictures))
      
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
  
  name_file_csv<-paste("All_Exif_metadata_",session_id,".csv",sep="")
  # write.csv(CSV_total, name_file_csv,row.names = F)
  # saveRDS(CSV_total, paste("All_Exif_metadata_",session_id,".RDS",sep=""))
  
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
  
  name_file_csv<-paste("Core_Exif_metadata_",session_id,".csv",sep="")
  # write.csv(metadata_pictures, name_file_csv,row.names = F)
  saveRDS(metadata_pictures, paste("Core_Exif_metadata_",session_id,".RDS",sep=""))
  
  # return(nrow(read.csv("Core_Exif_metadata.csv")))
  return(head(metadata_pictures))
}


# ELEMENTS A TESTER SUR CSV ALL METADATA
# CSV_total$PreviewImage[1] 
# CSV_total$PreviewImage[1] 
# CSV_total$ThumbnailImage[1] 
# CSV_total$ThumbnailOffset[1]
# CSV_total$ThumbnailLength[1]

extract_exif_metadata_in_this_directory <- function(images_directory,this_directory,template_df, mime_type = "*.JPG", time_zone="Indian/Mauritius"){
  setwd(this_directory)
  
  log <- paste("Adding references for photos in ", this_directory, "\n", sep=" ")
  parent_directory <- gsub(dirname(dirname(dirname(this_directory))),"",dirname(dirname(this_directory)))
  parent_directory <- gsub("/","",parent_directory)
  
  files <- list.files(pattern = mime_type ,recursive = TRUE)
  exif_metadata <-template_df
  exif_metadata <- read_exif(files,quiet = FALSE)#DDD deg MM' SS.SS"
  exif_metadata$session_id = parent_directory
  exif_metadata$session_photo_number <-c(1:nrow(exif_metadata))# @julien => A INCREMENTER ?
  exif_metadata$relative_path = gsub(dirname(images_directory),"",this_directory)
  
  # # IF THERE IS NO GPS DATA WE ADD EXPECTED COLUMNS WITH DEFAULT VALUES NA
  if(is.null(exif_metadata$GPSLatitude)==TRUE){
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
  exif_metadata$GPSDateTime = as.POSIXct(unlist(exif_metadata$GPSDateTime),"%Y:%m:%d %H:%M:%SZ", tz="UTC")
  exif_metadata$DateTimeOriginal = as.POSIXct(unlist(exif_metadata$DateTimeOriginal),"%Y:%m:%d %H:%M:%S", tz=time_zone)
  exif_metadata$DateTimeOriginal <- format(exif_metadata$DateTimeOriginal, tz="UTC",usetz=TRUE)
  attr(exif_metadata$DateTimeOriginal,"tzone")
  # exif_metadata$GPSLatitude = as.numeric(exif_metadata$GPSLatitude)
  # exif_metadata$GPSLongitude = as.numeric(exif_metadata$GPSLongitude)
  exif_metadata$geometry_postgis <- NA
  exif_metadata$geometry_postgis = as.numeric(unlist(exif_metadata$geometry_postgis))
  exif_metadata$geometry_gps_correlate <- NA
  exif_metadata$geometry_gps_correlate = as.numeric(unlist(exif_metadata$geometry_gps_correlate))
  exif_metadata$geometry_native <- NA
  exif_metadata$geometry_native = as.numeric(unlist(exif_metadata$geometry_native))
  
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
############################ load_metadata_in_database ###################################################
#############################################################################################################


load_exif_metadata_in_database <- function(con, codes_directory, exif_metadata, create_table=FALSE){
  if(create_table==TRUE){
    query_create_exif_core_metadata_table <- paste(readLines(paste0(codes_directory,"SQL/create_exif_core_metadata_table.sql")), collapse=" ")
    create_exif_core_metadata_table <- dbGetQuery(con,query_create_exif_core_metadata_table)
    dbWriteTable(con, "photos_exif_core_metadata", exif_metadata, row.names=FALSE, append=TRUE)
  } else {
    ogc_fid_min <- dbGetQuery(con, paste0("SELECT max(ogc_fid) FROM photos_exif_core_metadata;"))+1
    if(is.na(ogc_fid_min)){ogc_fid_min=0}
    ogc_fid_max <- max(ogc_fid_min)+nrow(exif_metadata)-1
    exif_metadata$ogc_fid <-c(max(ogc_fid_min):ogc_fid_max)
    names(exif_metadata)
    exif_metadata <- exif_metadata[,c(15,1,2,3,4,5,6,7,8,9,10,11,12,13,14)]
    dbWriteTable(con, "photos_exif_core_metadata", exif_metadata, row.names=FALSE, append=TRUE)
  }
  # dbWriteTable(con, "photos_exif_core_metadata", All_Core_Exif_metadata[1:10,], row.names=TRUE, append=TRUE)
}


#############################################################################################################
############################ load_gps_tracks_in_database ###################################################
#############################################################################################################

load_gps_tracks_in_database <- function(con, codes_directory, gps_tracks, create_table=TRUE){
  if(create_table==TRUE){
    query_create_table <- paste(readLines(paste0(codes_directory,"SQL/create_tables_GPS_tracks.sql")), collapse=" ")
    create_Table <- dbGetQuery(con,query_create_table)
    dbWriteTable(con, "gps_tracks", gps_tracks, row.names=FALSE, append=TRUE)
  } else {
    dbWriteTable(con, "gps_tracks", gps_tracks, row.names=FALSE, append=TRUE)
  }
  query_update_table_spatial_column <- paste(readLines(paste0(codes_directory,"SQL/add_spatial_column.sql")), collapse=" ")
  update_Table <- dbGetQuery(con,query_update_table_spatial_column)
  
}


#############################################################################################################
############################ read_rtk ###################################################
#############################################################################################################
return_dataframe_gps_file <- function(wd, gps_file, type="TCX",session_id,load_in_database=FALSE){
  setwd(wd)
  if(type=="RTK"){
    rtk_file=gps_file
    gps_tracks <- read.csv(rtk_file,stringsAsFactors = FALSE)
    gps_tracks$fid <-c(1:nrow(gps_tracks))
    gps_tracks$session_id <- session_id
    head(gps_tracks)
    sapply(gps_tracks,class)
    select_columns = subset(gps_tracks, select = c(fid,session_id,latitude,longitude,height,GPST,age))
    head(select_columns)
    GPS_tracks_values = dplyr::rename(select_columns, fid=fid,session_id=session_id, latitude=latitude,longitude=longitude, altitude=height, heart_rate=age, time=GPST)
    head(GPS_tracks_values)
    names(GPS_tracks_values)
    sapply(GPS_tracks_values,class)
    GPS_tracks_values$fid <-c(1:nrow(GPS_tracks_values))
    GPS_tracks_values$session_id <- session_id
    GPS_tracks_values$heart_rate <- c(1:nrow(GPS_tracks_values))
    GPS_tracks_values$time <- as.POSIXct(GPS_tracks_values$time, "%Y/%m/%d %H:%M:%OS")
    GPS_tracks_values$the_geom <- NA
    head(GPS_tracks_values)
  } else if(type=="GPX"){
    gpx_file=gps_file
    track_points <- NULL
    track_points <- rgdal::readOGR(dsn = gpx_file, layer="track_points",stringsAsFactors = FALSE)
    # dbWriteSpatial(con_Reef_database, track_points, schemaname="public", tablename="pays", replace=T,srid=4326)
    slotNames(track_points)
    sapply(track_points@data,class)
    GPS_tracks_values <- NULL
    GPS_tracks_values <- dplyr::select(track_points@data,ele,time,track_fid)
    GPS_tracks_values$latitude <- coordinates(track_points)[,2]
    GPS_tracks_values$longitude <- coordinates(track_points)[,1]
    GPS_tracks_values$the_geom <- NA
    GPS_tracks_values$session_id <- session_id
    GPS_tracks_values$time <- as.POSIXlt(track_points@data$time, tz="UTC")-14400
    class(GPS_tracks_values$time)
    attr(GPS_tracks_values$time,"tzone")
    GPS_tracks_values= dplyr::rename(GPS_tracks_values, session_id=session_id, latitude=latitude,longitude=longitude, altitude=ele, heart_rate=track_fid, time=time, the_geom=the_geom)
    GPS_tracks_values$fid <-c(1:nrow(GPS_tracks_values))
    GPS_tracks_values <- GPS_tracks_values[,c(8,7,4,5,1,2,3,6)]
  } else if (type=="TCX"){
    # https://cran.r-project.org/web/packages/trackeR/vignettes/TourDetrackeR.html => duplicates are removed ?
    tcx_file=gps_file
    runDF <- NULL
    runDF <- readTCX(file=tcx_file, timezone = "UTC")
    existing_rows <- dbGetQuery(con_Reef_database, paste0("SELECT COUNT(*) FROM gps_tracks WHERE session_id='",session_id,"';"))
    if(is.na(existing_rows)){existing_rows=0}
    start <- as.integer(existing_rows+1)
    end <- as.integer(existing_rows+nrow(runDF))
    runDF$fid <-c(start:end)
    runDF$session <- session_id
    select_columns = subset(runDF, select = c(fid,session,latitude,longitude,altitude,time,heart.rate))
    GPS_tracks_values = dplyr::rename(select_columns, fid=fid, session_id=session, latitude=latitude,longitude=longitude, altitude=altitude, heart_rate=heart.rate, time=time)
    names(GPS_tracks_values)
    GPS_tracks_values$the_geom <- NA
    class(GPS_tracks_values$time)
    attr(GPS_tracks_values$time,"tzone")
  }
  
  if(load_in_database==TRUE){load_gps_tracks_in_database(con_Reef_database, codes_directory, GPS_tracks_table, create_table=FALSE)}
  
  return(GPS_tracks_values)
  
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
  plotRoute(this_session_gps_tracks, zoom = 13, source = "google")
  dev.off()
  setwd(original_directory)
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
############################ infer_photo_location_from_gps_tracks ###################################################
#############################################################################################################

infer_photo_location_from_gps_tracks <- function(con, images_directory, codes_directory, session_id, offset, create_view=FALSE){
  original_directory <- getwd()
  setwd(images_directory)
  query <- NULL
  query <- paste(readLines(paste0(codes_directory,"SQL/template_interpolation_between_closest_GPS_POINTS_new.sql")), collapse=" ")
  query <- gsub("session_2018_03_24_kite_Le_Morne",session_id,query)
  if(offset < 0){
    query <- gsub("- interval","+ interval",query)
    # query <- gsub("41",abs(offset)-1,query)
    query <- gsub("42",abs(offset),query)
  }else{
    query <- gsub("41",abs(offset)-1,query)
    query <- gsub("42",abs(offset),query)
  }
  writeLines(query)
  
  inferred_location <- dbGetQuery(con, query)
  head(inferred_location)
  setwd(paste0(images_directory,"/GPS"))
  write.csv(inferred_location, "photos_location.csv",row.names = F)
  setwd(original_directory)
  
  if(create_view==FALSE){
    drop_view <- dbGetQuery(con_Reef_database, paste0('DROP VIEW IF EXISTS view_',session_id,';'))
  }
  
  return(inferred_location)
}