x <- "file:///media/julien/3465-3131/DCIM/332GOPRO/G0061737.JPG"
sub('.*\\/DCIM', '', x)
wd <- "/media/julien/Deep_Mapping_two/data_deep_mapping"
df <- return_dataframe_tag_txt(wd)
df

return_dataframe_tag_txt <- function(wd){
  setwd(wd)
  dataframe_csv_files <- NULL
  dataframe_csv_files <- data.frame(session=character(), path=character(), file_name=character())
  sub_directories <- list.dirs(path=wd,full.names = TRUE,recursive = TRUE)
  sub_directories  
  for (i in sub_directories){
    if (substr(i, nchar(i)-4, nchar(i))=="LABEL"){
      setwd(i)
      cat(dirname(i))
      name_session <-gsub(paste(dirname(dirname(i)),"/",sep=""),"",dirname(i))
      files <- list.files(pattern = "*.txt")
      # if(length(files)==1){
      if(length(files)>0){  
        csv_files <- files
        newRow <- data.frame(session=name_session,path=i,file_name=csv_files)
        dataframe_csv_files <- rbind(dataframe_csv_files,newRow)
        for (f in files){
          fileName <-  paste0("/tmp/",name_session,"_",gsub(".txt",".csv",f))
          system(paste0("cp ",paste0(i,"/",f)," ", fileName))
          tx2  <- readChar(fileName, file.info(fileName)$size)
          tx2  <- gsub(pattern = "[\r\n]+", replace = "\n", x = tx2)
          # tx2  <- gsub(pattern = "\\n", replace = paste0("\n",i,";"), x = tx2)
          tx2  <- gsub(pattern = "=>", replace = ";", x = tx2)
          tx2  <- gsub(pattern = "  ", replace = " ", x = tx2)
          tx2  <- gsub(pattern = " ; ", replace = ";", x = tx2)
          tx2  <- gsub(pattern = " , ", replace = ";", x = tx2)
          # writeChar(tx2, con=paste0("/tmp/",name_session,"_tags_bis.csv"))
          fileName_bis <-  gsub(pattern = ".csv", replace = "_bis.csv", x = fileName)
          writeLines(tx2, con=fileName_bis)
          fileName_ter <-  gsub(pattern = ".csv", replace = "_ter.csv", x = fileName)
          writeLines(gsub(pattern = '.*\\/DCIM', replace = paste0(name_session,"/DCIM"), readLines(con <- file(fileName_bis))),con=fileName_ter)
        }
        
    } else {
      cat("\ CHECK\n")
      cat(i)
      cat("\n")
    }
    }
  }
  return(dataframe_csv_files)
}