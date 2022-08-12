79	"all_seatizen_photos"	"abstract:This dataset is made of all photos stored in the database"	"All  photos"	"GENERAL: Mauritius, Seatizen, coral reef, underwater photos, deep learning, coral reef habitats, citizen sciences, Kite surfing;"	"owner:emmanuel.blondel1@gmail.com;
pointOfContact:julien.barde@ird.fr,wilfried.heintz@inra.fr"	"2017-11-04"	"dataset"	"SRID=4326;LINESTRING (57.31768 -20.46521, 57.31787 -20.46545, 57.31766 -20.4657, 57.31786 -20.4656, 57.31795 -20.46568, 57.3181 -20.46543, 57.31881  -20.4649, 57.31775 -20.46517, 57.31754 -20.46518)"	"2015-01-01T17:14:11Z/2015-01-01T19:05:59Z"	"eng"	"thumbnail:session_2017_11_04_kite_Le_Morne@https://drive.google.com/uc?id=1lW0Q7mY7hWkDBq3QKHUkNTt4plPrVb2I;
http:map(pdf)@https://drive.google.com/uc?id=1kdlTQDpj6G4fWm9pOQnUzeqWvo5n0rQC"	"use:terms1;"	"camera;"	"statement:This is some data quality statement providing information on the provenance"		"source:Postgis;
sourceType:dbquery;
uploadType:dbquery;
sql:""SELECT photo_id, session_id AS ""datasetID"",  session_photo_number, relative_path AS photo_relative_file_path, ""GPSLatitude"" AS ""decimalLatitude"", ""GPSLongitude"" AS ""decimalLongitude"", ""GPSDateTime"",  ""DateTimeOriginal"", ""FileName"", ""Make"", ""Model"", ""LightValue"",""ImageSize"", ""URL_original_image"", geometry_gps_correlate AS the_geom FROM ""photos_exif_core_metadata""   WHERE geometry_gps_correlate IS NOT NULL "";
sourceSql:""SELECT photo_id, session_id AS ""datasetID"",  session_photo_number, relative_path AS photo_relative_file_path, ""GPSLatitude"" AS ""decimalLatitude"", ""GPSLongitude"" AS ""decimalLongitude"", ""GPSDateTime"",  ""DateTimeOriginal"", ""FileName"", ""Make"", ""Model"", ""LightValue"",""ImageSize"", ""URL_original_image"", geometry_gps_correlate AS the_geom FROM ""photos_exif_core_metadata"" LIMIT 1"";
layername:all_seatizen_photos;
style:point;
attribute:Model[Model],Make[Make];
variable:LightValue[LightValue]"	"0102000020EB3D7734C0"	"10000"
