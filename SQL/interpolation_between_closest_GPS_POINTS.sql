SELECT photos_exif_core_metadata.session_id,photos_exif_core_metadata.session_photo_number,photos_exif_core_metadata.datetimeor, ST_AsEWKT(ST_Line_Interpolate_Point(the_line, 0.50))
FROM
photos_exif_core_metadata,
(SELECT ST_AsEWKT(ST_MakeLine(gps_tracks.the_geom)) AS the_line FROM gps_tracks, photos_exif_core_metadata  WHERE ( gps_tracks.time=(photos_exif_core_metadata.datetimeor::timestamp - interval '13400 second') OR gps_tracks.time=(photos_exif_core_metadata.datetimeor::timestamp) - interval '13401 second') AND gps_tracks.session_id='session_2018_02_25_paddle_Le_Morne') AS foo ;


--(gps_tracks.time=(photos_exif_core_metadata.datetimeor::timestamp - interval '13400 second') OR time=(photos_exif_core_metadata.datetimeor::timestamp) - interval '13401 second' )
--, MIN(gps_tracks.time), MIN(gps_tracks.time)



SELECT photos.session_id, 
photos."FileName", photos.session_photo_number, gps_tracks.fid, photos."DateTimeOriginal"as Clock_Camera, gps_tracks."time"as Clock_GPS, photos."GPSDateTime" as Clock_GPS_Camera, photos."GPSLatitude", photos."GPSLongitude" 
FROM photos_exif_core_metadata photos, gps_tracks 
WHERE gps_tracks."time"=photos."DateTimeOriginal" LIMIT 300;


SELECT 
photos.session_id, 
photos."FileName", 
photos.session_photo_number, 
gps_tracks.fid AS GPS_point_id, 
photos."DateTimeOriginal"as Clock_Camera, 
gps_tracks."time"as Clock_GPS, 
photos."GPSDateTime" as Clock_GPS_Camera,
gps_tracks."latitude",  
gps_tracks."longitude",
photos."GPSLatitude" AS "latitude_photo", 
photos."GPSLongitude" AS "longitude_photo"
FROM photos_exif_core_metadata photos, gps_tracks 
WHERE (gps_tracks."time"=(photos."DateTimeOriginal" - interval '260 second'))  LIMIT 700;



SELECT COUNT(session_photo_number.*) 
FROM photos_exif_core_metadata photos, gps_tracks 
WHERE (gps_tracks."time"=(photos."DateTimeOriginal" - interval '260 second'))  LIMIT 10; 



SELECT photos.session_id, COUNT(photos.*) AS COUNT_photos, gps_tracks.fid AS GPS_trackpoint_id, ST_MakeLine(gps_tracks.the_geom) AS segment 
FROM photos_exif_core_metadata photos, gps_tracks 
WHERE (gps_tracks."time"=(photos."DateTimeOriginal" - interval '260 second'))  
GROUP BY gps_tracks."time", photos.session_id , gps_tracks.fid 
ORDER BY gps_tracks.fid 
LIMIT 10; 
 

SELECT session_id, COUNT_photos FROM (SELECT photos.session_id AS session_id, COUNT(photos.*) AS COUNT_photos, gps_tracks.fid AS GPS_trackpoint_id, ST_MakeLine(gps_tracks.the_geom) AS segment 
FROM photos_exif_core_metadata photos, gps_tracks 
WHERE (gps_tracks."time"=(photos."DateTimeOriginal" - interval '260 second'))  
GROUP BY gps_tracks."time", photos.session_id , gps_tracks.fid 
ORDER BY gps_tracks.fid 
LIMIT 10 ) AS foo;
 

----------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------SELECTION DES GEOM (POINTS OU SEGMENT SI PLUSIEURS PHOTOS ENTRE DEUX POINTS GPS ------------
----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT session_id, GPS_trackpoint_id, COUNT("FileName") AS count_photos, string_agg("FileName", ', '), ST_MakeLine(the_geom) AS segment 
FROM (
SELECT photos.session_id AS session_id, gps_tracks.fid AS GPS_trackpoint_id, photos."FileName", gps_tracks.the_geom
FROM photos_exif_core_metadata photos, gps_tracks 
WHERE (gps_tracks."time"=(photos."DateTimeOriginal" - interval '260 second'))  
ORDER BY gps_tracks.fid, photos."FileName"
LIMIT 10 ) AS foo
GROUP BY session_id, GPS_trackpoint_id 
ORDER BY session_id
;



----------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------SELECTION DES DEUX POINTS GPS QUI ENCADRENT CHAQUE PHOTO----------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------


SELECT photos.session_id AS session_id, gps_tracks.fid AS GPS_trackpoint_id, photos."FileName", gps_tracks.the_geom
FROM photos_exif_core_metadata photos, gps_tracks 
WHERE (gps_tracks."time"=(photos."DateTimeOriginal" - interval '260 second') OR gps_tracks."time"=(photos."DateTimeOriginal" - interval '261 second'))  
ORDER BY gps_tracks.fid, photos."FileName"
LIMIT 10 


----------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------IDEM EN CREANT LE SEGMENT CORRESPONDANT AUX DEUX POINTS ----------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT row_number() OVER(ORDER BY session_id) AS OID, session_id, "FileName",array_agg(GPS_trackpoint_id ORDER BY GPS_trackpoint_id ASC) AS list_gps_points, ST_AsEWKT(ST_MakeLine(the_geom)) AS segment 
FROM (
SELECT photos.session_id AS session_id, gps_tracks.fid AS GPS_trackpoint_id, photos."FileName", gps_tracks.the_geom
FROM photos_exif_core_metadata photos, gps_tracks 
WHERE (gps_tracks."time"=(photos."DateTimeOriginal" - interval '260 second') OR gps_tracks."time"=(photos."DateTimeOriginal" - interval '261 second'))  
LIMIT 1000 ) AS foo 
GROUP BY session_id, "FileName" 
ORDER BY session_id, "FileName" ;


SELECT 
row_number() OVER(ORDER BY session_id) AS OID, 
session_id, "FileName", 
array_agg(GPS_trackpoint_id) AS list_gps_points, 
--array_length(array_agg(GPS_trackpoint_id),1),
ST_AsEWKT(ST_MakeLine(the_geom)) AS segment,
ST_AsEWKT(ST_Line_Interpolate_Point(the_line, 0.50)) AS interpolated_points
FROM (
SELECT photos.session_id AS session_id, gps_tracks.fid AS GPS_trackpoint_id, photos."FileName", gps_tracks.the_geom
FROM photos_exif_core_metadata photos, gps_tracks 
WHERE (gps_tracks."time"=(photos."DateTimeOriginal" - interval '260 second') OR gps_tracks."time"=(photos."DateTimeOriginal" - interval '261 second'))  
LIMIT 1000 ) AS foo 
GROUP BY session_id, "FileName" 
ORDER BY session_id, "FileName" ;



----------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------SELECTION DES DEUX POINTS GPS QUI ENCADRENT CHAQUE PHOTO----------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT photos_exif_core_metadata."FileName",
	CASE 
		WHEN (photos_exif_core_metadata."FileName" LIKE list_photos[1] AND photos_in_segment=1)  THEN ST_AsEWKT(ST_LineInterpolatePoint(segment, 0.5))
		WHEN (photos_exif_core_metadata."FileName" LIKE list_photos[1] AND photos_in_segment=2)  THEN ST_AsEWKT(ST_LineInterpolatePoint(segment, 0.33))
		WHEN photos_exif_core_metadata."FileName" LIKE list_photos[2] THEN ST_AsEWKT(ST_LineInterpolatePoint(segment, 0.66))
		ELSE 'other'
       END
       

FROM photos_exif_core_metadata, 
(SELECT session_id, array_agg("FileName") AS list_photos, array_length(array_agg("FileName"),1) AS photos_in_segment, list_gps_points, segment
FROM 

(SELECT 
row_number() OVER(ORDER BY session_id) AS OID, 
session_id, "FileName", 
array_agg(GPS_trackpoint_id) AS list_gps_points, 
ST_AsEWKT(ST_MakeLine(the_geom)) AS segment 
FROM (
SELECT photos.session_id AS session_id, gps_tracks.fid AS GPS_trackpoint_id, photos."FileName", gps_tracks.the_geom
FROM photos_exif_core_metadata photos, gps_tracks 
WHERE (gps_tracks."time"=(photos."DateTimeOriginal" - interval '260 second') OR gps_tracks."time"=(photos."DateTimeOriginal" - interval '261 second'))  
-- LIMIT 1000 
) AS foo 
GROUP BY session_id, "FileName" 
ORDER BY session_id, "FileName") AS the_query  
GROUP BY  session_id, list_gps_points, segment
ORDER BY  session_id, list_gps_points
) AS final_query

WHERE list_photos @> ARRAY[photos_exif_core_metadata."FileName"]
--LIMIT 800
;





