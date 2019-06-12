setwd("/home/julien/Documents/all_sessions/tcx/")
type="TCX"
if (type=="TCX"){pattern = "*.tcx"} else if (type=="GPX"){pattern = "*.gpx"} else if (type=="RTK"){pattern = "*.rtk"}
files <- list.files(pattern = pattern)
gps_files <- files
cat(gps_files)

CSV_total <-NULL
for (i in gps_files){
  dataframe_gps_file=NULL
  cat(i)
  name_session <-gsub(".tcx","",i)
  load_in_database=FALSE
  dataframe_gps_file <-return_dataframe_gps_file(getwd(), i, type="TCX", name_session,load_in_database)
  write.csv(dataframe_gps_file, paste0(name_session,".csv"))  
  CSV_total <- rbind(CSV_total, dataframe_gps_file)
  
}

write.csv(CSV_total, "CSV_total.csv")
saveRDS(CSV_total, "CSV_total.RDS")