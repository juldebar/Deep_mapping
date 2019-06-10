data_GPS_folder <-"/somewhere/GPS/"
gpx_file_name <- ""
paste(data_GPS_folder,gpx_file_name,"|layerid=2",sep="")
qgis_project <- readLines("./qqgis_project.qgs",encoding="UTF-8")
qgis_project <- sub(pattern = "../../../../Téléchargements/15694506468.gpx|layerid=2", replacement = paste(data_GPS_folder,gpx_file_name,"|layerid=2",sep=""),  x = qgis_project)
qgis_project <- sub(pattern = "57.31209123099999658", replacement = lonmin, x = qgis_project)
qgis_project <- sub(pattern = "57.33597803100000334", replacement = lonmax, x = qgis_project)
qgis_project <- sub(pattern = "-20.48229265200000171", replacement = latmin, x = qgis_project)
qgis_project <- sub(pattern = "-20.46065199399999912", replacement = latmax, x = qgis_project)
qgis_project <- sub(pattern = paste(working_directory,"/trajectoriesDrifters_4873.shp",sep=""), replacement = shapefile_observation_path,  x = qgis_project)


qgis_project <- sub(pattern = paste(working_directory,"/output/",sep=""), replacement ="",  x = qgis_project)

qgis_namefile <- paste ("Session_name",drifter_identifier,".qgs",sep="")
write(qgis_project, file = qgis_namefile,ncolumns=1)
cat("qgis project created")


qgis --project  /home/julien/Bureau/CODES/Deep_mapping/template/qgis_project.qgs --snapshot /home/julien/Bureau/CODES/Deep_mapping/template/qgis_project.png --width 4096 --height 4096 --extent 57.31209123099999658,-20.48229265200000171,57.33597803100000334,-20.46065199399999912