SELECT 
	relative_path,
	"FileName" AS "SourceFile",
	latitude AS "GPSLatitude",
	longitude AS "GPSLongitude",
	mean_altitude AS "GPSAltitude",
	latitude AS "GPSLatitudeRef",
	longitude AS "GPSLongitudeRef",
	mean_altitude AS "GPSAltitudeRef" 
FROM 
public."view_session_2018_08_25_Zanzibar_Snorkelling" 
;
