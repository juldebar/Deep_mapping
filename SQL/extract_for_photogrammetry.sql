SELECT 
	"FileName" AS "SourceFile",
	latitude AS "GPSLatitude",
	longitude AS "GPSLongitude",
	mean_altitude AS "GPSAltitude",
	latitude AS "GPSLatitudeRef",
	longitude AS "GPSLongitudeRef",
	mean_altitude AS "GPSAltitudeRef" 
FROM 
public."view_session_2018_05_12_snorkelling_Balacava"  
WHERE 
ST_WITHIN(the_geom,
ST_GeomFromText('POLYGON((57.50845353750469 -20.079443599330997,57.50883977560284 -20.079443599330997,57.50883977560284 -20.079766053734087,57.50845353750469 -20.079766053734087,57.50845353750469 -20.079443599330997))',4326))

;
