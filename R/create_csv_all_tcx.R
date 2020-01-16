setwd("/media/juldebar/Deep_Mapping_4To/data_deep_mapping/GPS_tracks/")
type="TCX"
if (type=="TCX"){pattern = "\\.tcx"} else if (type=="GPX"){pattern = "*.gpx"} else if (type=="RTK"){pattern = "*.rtk"}
files <- list.files(pattern = pattern, recursive = TRUE)
gps_files <- files
cat(gps_files)


CSV_total <-NULL
for (i in gps_files){
  dataframe_gps_file=NULL
  cat(paste0("\n File : \n",i," \n"))
  name_session <-gsub(".tcx","",i)
  load_in_database=FALSE
  dataframe_gps_file <-return_dataframe_gps_file(getwd(), i, type="TCX", name_session,load_in_database)
  write.csv(dataframe_gps_file, paste0(name_session,".csv"))  
  CSV_total <- rbind(CSV_total, dataframe_gps_file)
}

write.csv(CSV_total, "CSV_total.csv")
saveRDS(CSV_total, "CSV_total.RDS")

wd <- "/home/juldebar/Téléchargements/"
wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/"
wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/GPS_tracks/"

setwd(wd)
type="TCX"
if (type=="TCX"){pattern = "*.tcx"} else if (type=="GPX"){pattern = "*.gpx"} else if (type=="RTK"){pattern = "*.rtk"}
files <- list.files(pattern = pattern,recursive = TRUE)
gps_files <- files
cat(gps_files)

for (i in gps_files){
  date <-NULL
  dataframe_gps_file <- NULL
  pattern=NULL
  cat(paste0("\n \n**File : \n",i," \n"))
  name_session <-gsub(".tcx","",i)
  load_in_database=FALSE
  dataframe_gps_file <-return_dataframe_gps_file(getwd(), i, type="TCX", session_id="toto",load_in_database)
  #select date and replace "-" with "_"
  date <- gsub("-","_",strsplit(x = as.character(min(dataframe_gps_file$time))," ")[[1]][1])
  # paste(year(mommand)in(dataframe_gps_file$time)), month(min(dataframe_gps_file$time)), day(min(dataframe_gps_file$time)),sep="_")
  pattern <- paste0("session_", gsub("-","_",date))
  cat(paste0("\n Looking for following pattern => ",pattern),"\n")
  dirs <- list.dirs(path = "/media/juldebar/Deep_Mapping_4To/data_deep_mapping")
  dirs_match <- grep(pattern, dirs, value = TRUE)
  if(length(dirs_match)>0){
    cat(paste0("\n Session found => ", dirs_match[1]))
    dirs_match_gps <- grep("GPS", dirs_match, value = TRUE)
    if(length(dirs_match_gps)>0){
      cat(paste0("\n GPS directory has been found ! => ",dirs_match_gps[1],"\n"))
      command <- paste0("cp ", paste0(wd,i), " ",dirs_match_gps)
      if(file.exists(i)){
        cat(paste0("\n File ",i," already exists\n"))
        
      }
      # cat(commaommand)nd)
      # system(command)
    }else{
      cat(paste0("\n GPS directory not found for session", dirs_match[1],"!! \n"))
      gps_dir <-paste0(dirs_match[1],"/GPS")
      command <- paste0("mkdir ", gps_dir, " ; ","cp ", paste0(wd,i), " ",gps_dir)
      cat(command)
      system(command)
    }
  }else {
    cat(paste0("\n Session ",pattern," does not exist! \n"))
    command <- paste0("mkdir ", paste0(wd,pattern), " ;")
    cat(command)
  }
  
  # command <- paste0("\n mv ", gps_files[i])
  # cat(command)
  
  # copy file to directory which starts with 
  # write.csv(dataframe_gps_file, paste0(name_session,".csv"))  
  # CSV_total <- rbind(CSV_total, dataframe_gps_file)
}

