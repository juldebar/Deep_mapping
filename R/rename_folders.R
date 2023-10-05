setwd("/media/julien/Backup_Total_12T/Backup_Deep_Mapping/Underwater/rename")
dirlist<-list.dirs(recursive = FALSE)
country_code <- "_MDG-"
# sapply(dirlist[is.pattern],FUN=function(eachPath){ 
  # file.rename(from=eachPath,to= sub(pattern= pattern[i,2],replacement = pattern[i,1],eachPath))
  
  for (d in dirlist){
    old_name <- sub("./","",d)
    new_name <- sub("session_","",old_name)
    new_name <- sub(substr(new_name, 1, 10),gsub("_","",substr(new_name, 1, 10)),new_name)
    if(grepl("snorkelling",new_name)){
      new_name <-  paste0(sub("snorkelling_",country_code,new_name),"--scuba")
    }
    if(grepl("snorkeling",new_name)){
      new_name <-  paste0(sub("snorkeling_",country_code,new_name),"--scuba")
    }
    if(grepl("pmt",new_name)){
      new_name <-  paste0(sub("pmt_",country_code,new_name),"--scuba")
    }
    if(grepl("kite",new_name)){
      new_name <- paste0(sub("kite_",country_code,new_name),"--kite")
    }
    if(grepl("paddle",new_name)){
      new_name <- paste0(sub("paddle_",country_code,new_name),"--paddle")
    }
    if(grepl("surf",new_name)){
      new_name <- paste0(sub("surf_",country_code,new_name),"--surf")
    }
    new_name <- gsub("_","-",new_name)
    new_name <- gsub("--","_",new_name)
    
    cat(paste0(new_name,sep="\n"))
    
    con <- file(paste(old_name,"LABEL","tag.txt",sep="/"),"r")
    lines <- readLines(con)
    close(con)
    new_lines <- gsub(old_name,new_name,lines)
    cat(paste0(new_lines,sep="\n"))
    fileConn<-file(paste0(d,"/LABEL/new_tag.txt"))
    writeLines(new_lines, fileConn)
    close(fileConn)
    file.rename(from=d,to=new_name)
    
    
  }
