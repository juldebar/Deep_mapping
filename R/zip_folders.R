library(R.utils)
library(zip)
# sapply(dirlist[is.pattern],FUN=function(eachPath){ 
# file.rename(from=eachPath,to= sub(pattern= pattern[i,2],replacement = pattern[i,1],eachPath))
# setwd("/media/julien/SSD2TO/Deep_Mapping/drone/Madagascar/2023")
setwd("/media/julien/Backup_Total_12T/Backup_Deep_Mapping/Drone/Madagascar/2023/new")
this_wd <- getwd()
dirlist<-list.dirs(recursive = FALSE)
replace_DCIM <- TRUE
replace_LABEL <- TRUE
replace_METADATA <- TRUE
replace_GPS <- TRUE


for (d in dirlist){
  setwd(d)
  cat(paste0("\n Browsing",d," !"))
  mission_wd <- getwd()
    if(!dir.exists("DCIM") && file.exists("DCIM.zip")){
      unzip(zipfile = './DCIM.zip', exdir="DCIM",overwrite = FALSE)
    }

  setwd(this_wd)
  
}


for (d in dirlist){
  setwd(d)
  cat(paste0("\n Browsing",d," !"))
  mission_wd <- getwd()
  subdirlist<-list.dirs(path=getwd(),recursive = FALSE)
  for (sub in subdirlist){
    setwd(sub)
    if(!dir.exists(file.path(sub, "ZENODO"))){
      cat(paste0("\n","Zenodo !"))
      dir.create(file.path(sub, "ZENODO"))
    }
    if(dir.exists("DCIM") && replace_DCIM){
      files2zip <- NULL
      cat(paste0("\n","DCIM !"))
      mediadirlist <- dir('DCIM', full.names = TRUE) %>% str_subset(pattern = "MEDIA")
      # mediadirlist<-list.dirs(path="./DCIM",recursive = FALSE) %>% str_subset(pattern = "MEDIA")
      cat(paste0("\n",mediadirlist))
        zip(zipfile = './ZENODO/DCIM.zip', files = 'DCIM',recurse = TRUE,include_directories = TRUE)
    }
  if(dir.exists("LABEL") && replace_LABEL){
    files2zip <- NULL
    cat(paste0("\n","LABEL !"))
    files2zip <- dir('LABEL', full.names = TRUE)
    # length(files2zip)
    filename <- "./LABEL/tag.txt"
    if(file.exists(filename)){
      con <- file(filename,"r")
      if(sapply(filename,countLines)>1){
        files2zip <- dir('LABEL', full.names = TRUE)
        cat(paste0("\n",files2zip))
        # zip(zipfile = './ZENODO/LABEL.zip', files = sapply)
        zip(zipfile = './ZENODO/LABEL.zip', files = files2zip,include_directories = TRUE)
      }
      first_line <- readLines(con)
      # first_line <- readLines(con,n=1)
      close(con)
    }
  }
  if(dir.exists("METADATA") && replace_METADATA){
    metadatafiles <- NULL
    cat(paste0("\n","METADATA ! => ",getwd()),"\n")
    rootfiles <- substr(dir(full.names = TRUE),3,200)
    file.rename(from=rootfiles, to=gsub(" ","_",rootfiles))
    jsonfiles <- rootfiles[grepl(".json",rootfiles)]
    p4dfiles <- rootfiles[(grepl(".p4d",rootfiles)|grepl("pix4dcapture",rootfiles))]
    rootfiles <- c(jsonfiles,p4dfiles)
    if(length(rootfiles)!=0){
      file.rename(from=rootfiles, to=paste0("./METADATA/ ",rootfiles))
    }
    metadatafiles <- dir('METADATA', full.names = TRUE)
    # files2zip <- c(metadatafiles,jsonfiles,p4dfiles)
    cat(paste0("\n",FALSE))
    zip(zipfile = './ZENODO/METADATA.zip', files = metadatafiles,include_directories = TRUE)
    # zip_append(zipfile = './ZENODO/METADATA.zip',root=".", files = c(jsonfiles,p4dfiles),include_directories = TRUE)
  }
    
  if(dir.exists("GPS") && replace_GPS){
    files2zip <- NULL
    files2zip <- dir('GPS', full.names = TRUE)
    files2zip <- files2zip[! (grepl("sql",files2zip) |  grepl("osm",files2zip))]
    cat(paste0("\n",files2zip))
    zip(zipfile = './ZENODO/GPS.zip', files = files2zip,include_directories = FALSE)
    file.copy(from = files2zip[grepl(".jpeg",files2zip)],to=getwd())
  }
  }
  
  files <- list.files(pattern = "a_raw_drone_data_map_preview.jpg" ,recursive = TRUE)
  files <-  c(files,list.files(pattern =".jpeg" ,recursive = FALSE))
  files <- c(files,list.files(pattern =".pdf" ,recursive = FALSE))
  files <- c(files,list.files(pattern =".gpkg" ,recursive = FALSE))
  files <- c(files,list.files(pattern =".html" ,recursive = FALSE))
  
  for(f in files){
    file.copy(from = f,to="./ZENODO/")
  }
  # setwd(setwd(d))
  setwd(this_wd)
  
}

