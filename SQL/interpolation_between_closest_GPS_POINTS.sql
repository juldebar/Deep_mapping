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


SELECT photos.session_id, 
photos."FileName", photos.session_photo_number, gps_tracks.fid, photos."DateTimeOriginal"as Clock_Camera, gps_tracks."time"as Clock_GPS, photos."GPSDateTime" as Clock_GPS_Camera, photos."GPSLatitude", photos."GPSLongitude" 
FROM photos_exif_core_metadata photos, gps_tracks 
WHERE (gps_tracks."time"=(photos."DateTimeOriginal" - interval '260 second') OR gps_tracks.time=(photos."DateTimeOriginal" - interval '261 second'))  LIMIT 800;


 
 
