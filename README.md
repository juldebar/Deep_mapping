This is a repository providing R codes to manage underwater pictures and their spatial location

In this repository we use: 
 - [exifr](https://www.r-bloggers.com/extracting-exif-data-from-photos-using-r/) package to extract exif metadata from JPG images
 - 
 
 
 Data collected have to comply with the following file structure:
 
<img style="position: absolute; top: 0; right: 0; border: 0;" src="http://mdst-macroes.ird.fr/BlueBridge/Ichtyop/Ichthyop_tree_structure.svg" width="500">

Our goal is to use this data structure as an input for R codes which will parse the subdirectories and files to load information in a Postgres / Postgis database with the following conceptual model:
 
<img style="position: absolute; top: 0; right: 0; border: 0;" src="https://drive.google.com/uc?id=1KTMUd6SQ9UGR3xMrtDYsAB0vNSYUlUZ5" width="500">


The main steps of the workflow are :
 - `extract` general metadata (~ Dublin Core) from google spreadsheet and load them in a dedicated table of the database
 - extract metadata from photos with exifr package and load them them in a dedicated table of the database
 - **extract** data from GPS tracks (txc or gpx files) and load them them in a dedicated table of the database
 - correlation of GPS timestamps and photos timestamps to infer photos locations (done with a SQL query / trigger in Postgis)
 
 
~~~~
ffmpeg -y -i GOPR0001.MP4 -codec copy -map 0:m:handler_name:"	GoPro MET" -f rawvideo GOPR0001.bin
R codes
~~~~