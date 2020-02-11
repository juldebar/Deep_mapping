########################################################################################################################################################################
########################################################################################################################################################################
require(stringr)
require(dplyr)
require(tidyr)
library(googledrive)
########################################################################################################################################################################
########################################################################################################################################################################
# google_drive_path <- drive_get(id="1I_G1_GYIXOUBCJZLHD_ggKZvLVcdtd_2pcTkCiltzSU")
# google_drive_file <- upload_google_drive(google_drive_path,"all.csv")
# google_drive_file_url <- paste0("https://drive.google.com/open?id=",google_drive_file$id)
# google_drive_file %>% drive_reveal("permissions")
# google_drive_file %>% drive_reveal("published")
# google_drive_file <- google_drive_file %>% drive_share(role = "reader", type = "anyone")
# google_drive_file %>% drive_reveal("published")
# google_drive_file <- drive_publish(as_id(google_drive_file$id))
########################################################################################################################################################################
########################################################################################################################################################################

# Function to merge the annotations of images coming from different files (one per session / survey)
return_dataframe_tag_txt <- function(wd){
  setwd(wd)
  dataframe_csv_files <- NULL
  dataframe_csv_files <- data.frame(session=character(), path=character(), file_name=character())
  sub_directories <- list.dirs(path=wd,full.names = TRUE,recursive = TRUE)
  sub_directories  
  for (i in sub_directories){
    if (substr(i, nchar(i)-4, nchar(i))=="LABEL"){
      setwd(i)
      path_session <-dirname(i)
      cat(paste0(i,"\n"))
      cat(paste0(path_session,"\n"))
      name_session <-gsub(paste(dirname(path_session),"/",sep=""),"",path_session)
      files <- list.files(pattern = "*.txt")
      # if(length(files)==1){
      if(length(files)>0){
        csv_files <- files
        newRow <- data.frame(session=name_session,path=i,file_name=csv_files)
        dataframe_csv_files <- rbind(dataframe_csv_files,newRow)
        for (f in files){
          csv_file <-NULL
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
          
          # tx2  <- gsub(pattern = '.*\\/DCIM', replace = paste0(path,"/DCIM"),x = tx2)
          # writeChar(tx2, con=paste0("/tmp/",name_session,"_tags_bis.csv"))
          fileName_bis <-  gsub(pattern = ".csv", replace = "_bis.csv", x = fileName)
          writeLines(tx2, con=fileName_bis)
          
          fileName_ter <-  gsub(pattern = ".csv", replace = "_ter.csv", x = fileName)
          # csv_file <- readLines(con <- file(fileName_bis))
          csv_file <- read.csv(fileName_bis,sep = ",")
          csv_file$path <- gsub(pattern = '.*\\/DCIM', replace = paste0(path_session,"/DCIM"),x = csv_file$path)
          csv_file$name_session <- gsub("/","",name_session)
          csv_file$file_name <-gsub(pattern = '.*\\/G0',"G0",csv_file$path)
          head(csv_file)
          # writeLines(csv_file,con=fileName_ter)
          write.table(x = csv_file,file = fileName_ter, sep=",",row.names = FALSE)
          # system(paste0("rm ",fileName))
          # system(paste0("rm ",fileName_bis))
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


# we use the "return_dataframe_tag_txt" function to create a single file which gathers all annotations (from all sessions) and store it in the given repository (wd)
wd <- "/media/juldebar/Deep_Mapping_one1"
wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2017"
# wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/A/"
# wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2018/GOOD"
# wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019"
wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/all_txt_gps_files"
df <- return_dataframe_tag_txt(wd)
head(df)

setwd("/tmp")
files <- list.files(pattern = "*ter.csv")
all_files <- NULL
all_files <- Reduce(rbind, lapply(files, read.csv))
head(all_files)
write.table(x = all_files,file = "all.csv", sep=",",row.names = FALSE)
newdf <- read.csv("all.csv",sep = ",")
newdf$photo_name=paste0(newdf$name_session,"_",newdf$file_name)
head(newdf)
system(command = "awk 'FNR==1 && NR!=1{next;}{print}' *ter.csv  > combined.csv")

google_drive_path_label <- drive_find(pattern = "Photos_tagging", type = "folder")
upload_file_on_drive_repository(google_drive_path_label,"all.csv")
                                

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
########################################################################################################################################################################
########################################################################################################################################################################
# Function to copy all annotated images in a single repository and/or in repositories whose name is the same as the label annotating images
copy_images_for_training <- function(wd_copy, all_images,file_categories,crop_images=FALSE){
  current_dir <- getwd()
  setwd(wd_copy)
  # create sub-repositories for  each object / category to be identified where all images tagged with this category will be copied
  for(dir in 1:nrow(file_categories)){
    #we filter the dataset to selectonly images tagged with the category (matching the pattern)
    mainDir <-  file_categories$RepositoryName[dir]
    relevant_images <- all_images %>% filter(str_detect(tag, file_categories$Pattern[dir]))
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
          # cat(command)
          # cat(paste0("cp ",paste0(as.character(relevant_images$path[f])," .",gsub(dirname(as.character(relevant_images$path[f])),"", as.character(relevant_images$path[f]))),"\n"))
          system(command)
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


# wd_copy <- "/media/julien/Deep_Mapping_two/trash"
dir.create("/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash")
wd_copy <- "/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash"
# We load the mapping between annotation and labels from either a csv or a google sheet
# all_categories <- read.csv("/home/julien/Bureau/CODES/Deep_mapping/CSV/All_categories.csv",stringsAsFactors = FALSE)
all_categories <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1mBQiokVvVwz3ofDGwQFKr3Q4EGnn8nSrA1MEzaFIOpc/edit?usp=sharing"))
# df_images <-all_files
df_images <-newdf
# head(df_images)
# newdf$path
df_images$path <- gsub("/media/juldebar/Deep_Mapping_4To/data_deep_mapping/all_txt_gps_files","/media/juldebar/Deep_Mapping_4To/data_deep_mapping",df_images$path)
crop_images=FALSE

# we make a copy of all annotated images
copy_images_for_training(wd_copy, df_images,all_categories,crop_images=crop_images)
# ckeck if sub-repositories exist
########################################################################################################################################################################
########################################################################################################################################################################

real <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1DMPuM382yuhkgfWnZAmhhQQed-fx6IMjsppcHbXXpV0/edit?usp=sharing"))
head(real)
real  %>% distinct(LABELS)

multi_labels <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1mBQiokVvVwz3ofDGwQFKr3Q4EGnn8nSrA1MEzaFIOpc/edit?usp=sharing"))
label_ime <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1be6-6T2t_SIXwG6hEnC68Z6u_bSOMlRM7pk09hatwqU/edit?usp=sharing"))

images <-NULL
images <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1I_G1_GYIXOUBCJZLHD_ggKZvLVcdtd_2pcTkCiltzSU/edit?usp=sharing"))
images$old_tag <-images$tag
images <- left_join(images, label_ime, by = 'file_name')
head(images)
images %>% distinct(tag)
images <- images %>% unite("tag", old_tag:Labels, remove = FALSE)
head(images)


total <-NULL
tag_to_label <- function(images,labels){
  #for each category we check if some images are tagged with this category
  for(pattern in 1:nrow(labels)){
    images_with_labels <- images %>% filter(str_detect(images$tag, labels$Pattern[pattern]))
    # images_with_labels$tag <-as.character(labels$Name[pattern])
    if(nrow(images_with_labels)>0){
      images_with_labels$tag <-labels$Name[pattern]
      head(images_with_labels)
      total <-bind_rows(total,images_with_labels)
      }
  }
return(total)
}

total <- tag_to_label(images,multi_labels)  

head(total)
duplicated(total)

total %>% group_by(tag)
total  %>% distinct(path)

# p <- function(v) {
#   Reduce(f=paste0, x = v)
# }
# test <- total %>%   group_by(path)  %>% summarise(bars_by_foo = p(as.character(tag))) %>%  merge(., total, by = 'path') %>%   select(path, tag, bars_by_foo)

test <-NULL
test <- total %>%   group_by(path,name_session,file_name,old_tag,Labels,WTF)  %>% summarise(tag = paste(tag, collapse=", "))
duplicated(test$path)
test %>% distinct(tag)
head(test)
test$URL <- paste0("http://162.38.140.205/tmp/Deep_mapping/",test$name_session,"_",test$file_name)
test
write.table(x = test,file = "labels.csv", sep=",",row.names = FALSE)

images_tags_and_labels <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/14XiNE6gvXjWZg9YAQZ-OWvdgYBDL6knoLD86ZRvx_jw/edit?usp=sharing"))
label_ime <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1be6-6T2t_SIXwG6hEnC68Z6u_bSOMlRM7pk09hatwqU/edit?usp=sharing"))


jointure <- left_join(images_tags_and_labels, label_ime, by = 'file_name')
head(jointure)
jointure


x <-"/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/Deep_Mapping/session_2019_10_14_kite_Le_Morne_kite_Lagoon/DCIM/101GOPRO/G0023767.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/Deep_Mapping/session_2019_10_14_kite_Le_Morne_kite_Lagoon/DCIM/101GOPRO/G0023778.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/Deep_Mapping/session_2019_10_14_kite_Le_Morne_kite_Lagoon/DCIM/101GOPRO/G0023780.JPG"
x <- "/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_01_13_kite_Le_Morne_G0016833.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_01_13_kite_Le_Morne_G0017618.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_01_13_kite_Le_Morne_G0017620.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_01_13_kite_Le_Morne_G0017641.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_01_13_kite_Le_Morne_G0017646.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_01_14_kite_Le_Morne_G0015875.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_01_14_kite_Le_Morne_G0015876.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_03_24_kite_Le_Morne_G0018507.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_03_24_kite_Le_Morne_G0018508.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_03_24_kite_Le_Morne_G0019179.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_03_24_kite_Le_Morne_G0019685.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_03_24_kite_Le_Morne_G0019686.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_03_24_kite_Le_Morne_G0019793.JPG
/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash/A/session_2018_03_24_kite_Le_Morne_G0024206.JPG"
content <- " et sable"
set_images <- strsplit(x, "\n")
df_enriched <- NULL
df_enriched <- images_tags_and_labels
head(df_enriched)
df_enriched$old_tag
df_enriched$new_tag <- "toto"

for(image in 1:lengths(set_images)){
  cat(paste0(image,"\n"))
  file_name <-gsub(".*\\/session","session",set_images[[1]][image])
  image_file_name <- gsub(".*_G0","G0",file_name)
  cat(paste0(file_name,"\n"))
  session <- gsub(paste0("_", image_file_name),"",image_file_name)
  cat(paste0(session,"\n"))
  image_row <- filter(df_enriched,name_session==session,file_name==image_file_name)
  if (nrow(image_row)>1){
    cat("Achtung")
  }
  df_enriched$old_tag[df_enriched$path==image_row$path] <- paste0(image_row$old_tag,content)
  # df_enriched <- mutate(df_enriched, new_tag = which(name_session==session,file_name==image_file_name), paste0(old_tag,content))
  # dat <- dat %>% mutate(col1 = replace(col1, which(is.na(col1) & col2 == "Tom"), 0))
  # enriched_tag <- paste0(previous_tag$old_tag,content)
  # image_row <- filter(df_enriched,name_session==session,file_name==image_file_name) %>% mutate(replace(new_tag == paste0(old_tag,content), NA))
  # filter(df_enriched,name_session==session,file_name==image_file_name) %>% mutate(replace(new_tag == paste0(old_tag,content), NA))
  # df_enriched <- df_enriched %>% mutate(name_session==session,file_name==image_file_name, new_tag = replace(new_tag = paste0(old_tag,content))) 
  # df_enriched <- mutate(df_enriched, new_tag = ifelse(name_session==session && file_name==image_file_name),paste0(old_tag,content), old_tag))
  
  # cat(paste0(previous_tag$old_tag,"\n"))
  # cat(paste0(enriched_tag,"\n"))
  
}

head(df_enriched)

wd_copy <- "/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash"
if(!dir.exists(wd_copy)){
  dir.create("/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/trash")
}
all_categories <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1mBQiokVvVwz3ofDGwQFKr3Q4EGnn8nSrA1MEzaFIOpc/edit?usp=sharing"))
df_images <-NULL
df_images <-df_enriched
df_images$tag <-df_images$old_tag
head(df_images)
crop_images=FALSE
# we make a copy of all annotated images
copy_images_for_training(wd_copy, df_images,all_categories,crop_images=crop_images)

