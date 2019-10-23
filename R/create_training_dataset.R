require(stringr)
require(dplyr)

# Function to merge annotations from different files
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
          system(paste0("sed -i '1 i\\","path;tag'"," ",fileName))
          
          tx2  <- readChar(fileName, file.info(fileName)$size)
          tx2  <- gsub(pattern = "[\r\n]+", replace = "\n", x = tx2)
          tx2  <- gsub(pattern = "[  ]+", replace = " ", x = tx2)
          tx2  <- gsub(pattern = "[   ]+", replace = " ", x = tx2)
          tx2  <- gsub(pattern = ",", replace = " et ", x = tx2)
          tx2  <- gsub(pattern = " => ", replace = ";", x = tx2)
          tx2  <- gsub(pattern = ";", replace = ",", x = tx2)
          tx2  <- gsub(pattern = "herbier marron", replace = "Thalassodendron ciliatum", x = tx2)
          tx2  <- gsub(pattern = "herbier vert", replace = "Syringodium isoetifolium", x = tx2)
          # writeChar(tx2, con=paste0("/tmp/",name_session,"_tags_bis.csv"))
          fileName_bis <-  gsub(pattern = ".csv", replace = "_bis.csv", x = fileName)
          writeLines(tx2, con=fileName_bis)
          fileName_ter <-  gsub(pattern = ".csv", replace = "_ter.csv", x = fileName)
          writeLines(gsub(pattern = '.*\\/DCIM', replace = paste0(dirname(i),"/DCIM"), readLines(con <- file(fileName_bis))), con=fileName_ter)
          system(paste0("rm ",fileName))
          system(paste0("rm ",fileName_bis))
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





# awk 'FNR==1 && NR!=1{next;}{print}' *ter.csv  > combined.csv
# on crée le fichier qui regroupe toutes les annotations
wd <- "/media/juldebar/Deep_Mapping_one1"
wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019"
df <- return_dataframe_tag_txt(wd)
df

setwd("/tmp")
files <- list.files(pattern = "*ter.csv")
all_files <- NULL
all_files <- Reduce(rbind, lapply(files, read.csv))
all_files
write.table(x = all_files,file = "all.csv", sep=";",row.names = FALSE)

system(command = "awk 'FNR==1 && NR!=1{next;}{print}' *ter.csv  > combined.csv")




# library(data.table)
# library(dplyr)
# slice(all_files, 1:5)
# filter(all_files, tag == "casier")
# filter(all_files, grepl("raie",tag) == TRUE)
# filter(all_files, grepl("herb",tag) == TRUE)
# filter(all_files, grepl("poiss",tag) == TRUE)
# filter(all_files, grepl("concom",tag) == TRUE)
# filter(all_files, grepl("zeb",tag) == TRUE)
# filter(all_files, grepl("bre",tag) == TRUE)
# filter(all_files, grepl("chauss",tag) == TRUE)
# 
# filter(all_files, tag == "bénitier")
# library(stringr)
# all_files %>% filter(str_detect(tag, "herb"))
# all_files %>% filter( grepl("herb",tag) == TRUE)
# 
# select(all_files, starts_with("p"))
# filter(all_files, tag %like% "cor")
# 
# newdf <- NULL
# newdf <- read.csv("all.csv",sep = ";")
# newdf$thalasso <-"0"
# head(newdf)
# for(new in 1:nrow(newdf)){
#   if (grepl(newdf$tag[new] == "Thalassodendron ciliatum")){
#     cat("OK")
#     newdf$thalasso[new] <-"1"
#   }
# }
# newdf
# 


copy_images_for_training <- function(wd_copy, df_images,file_categories,crop_images=FALSE){
  current_dir <- getwd()
  setwd(wd_copy)
  all_images <-df_images
  # create sub-repositories
  # dir <-1
  for(dir in 1:nrow(file_categories)){
    # file_categories[dir]
    mainDir <-  file_categories$RepositoryName[dir]

    relevant_images <- all_images %>% filter(str_detect(tag, file_categories$Pattern[dir]))
    if(nrow(relevant_images)>0){
      dir.create(mainDir)
      setwd(mainDir)
      if(crop_images){dir.create(file.path(mainDir, "crop"))}
    for(f in 1:nrow(relevant_images)){
      cat("\n")
      print(relevant_images$path[f])
      # cat(paste0(mainDir,f))
      cat("\n")

# check the clause below!
      if(length(relevant_images$path[f])>0){
        # copy relevant images for this category in this sub-repository (crop images if asked)
        filename <- gsub(paste0(dirname(as.character(relevant_images$path[f])),"/"),"", as.character(relevant_images$path[f]))
        cat(filename)
        cat("\n")
        # cat(paste0("cp ",paste0(as.character(relevant_images$path[f])," .",gsub(dirname(as.character(relevant_images$path[f])),"", as.character(all_images$path[f])))))
        cat(paste0("cp ",paste0(as.character(relevant_images$path[f])," .",gsub(dirname(as.character(relevant_images$path[f])),"", as.character(relevant_images$path[f])))))
        system(paste0("cp ",paste0(as.character(relevant_images$path[f])," .",gsub(dirname(as.character(relevant_images$path[f])),"", as.character(relevant_images$path[f])))))
      }else{
        cat(paste0("\n issue with ",relevant_images$path[f],"\n" ))
        
      }
      if(crop_images){crop_this_image(filename,mainDir)}
    }
  }
    setwd(wd_copy)
  }
  cat("done")
}


# wd_copy <- "/media/julien/Deep_Mapping_two/trash"
dir.create("/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash")
wd_copy <- "//media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash"
all_categories <- read.csv("/home/julien/Bureau/CODES/Deep_mapping/CSV/All_categories.csv",stringsAsFactors = FALSE)
file_categories <- all_categories
df_images <-all_files
crop_images=FALSE
copy_images_for_training(wd_copy, df_images,all_categories,crop_images=crop_images)
# ckeck if sub-repositories exist

