# load images and tags for original images
images_tags_and_labels <- as.data.frame(gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/14XiNE6gvXjWZg9YAQZ-OWvdgYBDL6knoLD86ZRvx_jw/edit?usp=sharing"))
head(images_tags_and_labels)

# load additional tags images added by Imene
train_val <- as.data.frame(gsheet::gsheet2tbl("https://drive.google.com/file/d/1-xs5cVxWPpieD969NSPnva4-8c3Y7uqa/view?usp=sharing"))
head(train_val)
nrow(train_val)
# identify row number of original images
original_images <- intersect(starts_with("G00",ignore.case = FALSE,train_val$ID),ends_with(".JPG",ignore.case = FALSE,train_val$ID))
head(original_images)
length(original_images)
# subset only original images (row numbers above)
list_images <- slice(train_val,original_images)  %>%   rename(file_name= ID,	URL_imene=URL, LABELS_imene=LABELS)
list_images$LABELS_imene <-gsub(" ",",",list_images$LABELS_imene)
head(list_images)
nrow(list_images)

#Merge the two datasets
jointure <- left_join(images_tags_and_labels, list_images, by = 'file_name')
head(jointure)
nrow(jointure)
jointure$new_tag <- gsub(",NA","",paste0(jointure$tag,",",jointure$LABELS_imene))
head(jointure)
# jointure$old_tag[jointure$path==image_row$path] <- gsub("NA","",paste0(image_row$old_tag,content))
# head(jointure)

#check if some labels are duplicated
jointure$new_label <- NULL
for (i in 1:nrow(jointure)){
  labels <- strsplit(jointure$new_tag[i],",")
  labels_number <- length(labels[[1]])
  if(labels_number>1){
    cat(paste0("\n",labels_number)," :\n")
    cat(labels[[1]])
    new_label <- NULL
    for (l in 1:labels_number){
      # cat("\n one by one :\n")
      # cat(paste0("\n",labels[[1]][l])," :\n")
      new_label <- gsub(labels[[1]][l],"",new_label)
      new_label <- paste(new_label," ",labels[[1]][l])
    }
    new_label <- gsub(" +"," ",new_label)
    cat("\n New label",new_label,"\n")
    jointure$new_label[i] <-new_label
  }else{
    jointure$new_label[i] <-jointure$new_tag[i]
    
  }
}
head(jointure)

write.table(x = jointure,file = "jointure.csv", sep=",",row.names = FALSE)
# clean if multiple occurences ...

