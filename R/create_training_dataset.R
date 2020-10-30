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


# we use the "return_dataframe_tag_txt" function to create a single file which gathers all annotations (from all sessions) and store it in the given repository (wd)
# wd <- "/media/juldebar/Deep_Mapping_one1"
wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2017"
# wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/A/"
wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2018/GOOD"
# wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019"
# wd <- "/media/juldebar/Deep_Mapping_4To/data_deep_mapping/all_txt_gps_files"
wd <-"/media/juldebar/Deep_Mapping_4To/data_deep_mapping/2019/good/validated"
wd <- "/media/juldebar/c7e2c225-7d13-4f42-a08e-cdf9d1a8d6ac/Deep_Mapping/new"
wd<-"/media/julien/3362-6161/session_2019_09_18_kite_Le_Morne_La_Pointe"
newdf <- return_dataframe_tag_txt(wd)
head(newdf)

tags_google_drive_path <- drive_get(id="1U6I6tgAqKRDgurb7gnQGV8Q5_i_jJSB4")
google_drive_path_label <- drive_find(pattern = "list_images_with_tags_and_labels", type = "folder")
upload_file_on_drive_repository(google_drive_path_label,"list_images_with_tags_and_labels")
tags_file_path <- drive_get(id="1eFJq003Z3JayIHtgupYfM01qV2IVT3VuBeYt6a0OKdM")
googledrive::drive_update(file=tags_file_path,name=file_name,media=file_name)


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


############################ copy all annotated images in  repositories whose name are the same as the label annotating images  ########################
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

