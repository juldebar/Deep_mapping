select * from gps_tracks where fid IN (939,940,941) and session_id='session_2018_03_31_kite_Le_Morne'
SELECT array_agg(gps_tracks.fid),time AS list_gps_points from gps_tracks  where session_id='session_2018_03_31_kite_Le_Morne' GROUP by time having count(*) > 1

SELECT session_id, array_agg(gps_tracks.fid) AS list_gps_points, array_agg(gps_tracks.time) AS time, ST_AsEWKT(ST_MakeLine(the_geom)) AS WKT, ST_MakeLine(the_geom) AS track from gps_tracks  where session_id='session_2018_03_31_kite_Le_Morne' GROUP by session_id;




--system("ogr2ogr -f GPX  -dsco GPX_USE_EXTENSIONS=YES points.gpx PG:'host=reef-db.d4science.org user=Reef_admin password=4b0a6dd24ac7b79 dbname=Reef_database' track_points -nlt POINT -sql \"select * from test_view \" ")




-- GIVES THE LIST OH PHOTOS WHICH HAVE EITHER LESS OR MORE THAN 2 GPS POINTS

SELECT 
  session_id, 
  array_agg("FileName") AS list_photos, 
  array_length(array_agg("FileName"),1) AS photos_in_segment, 
  list_gps_points, 
  count_gps_points, 
  segment         
FROM   
  (         
  SELECT
    row_number() OVER(ORDER BY session_id) AS OID,
    session_id, "FileName",
    array_agg(GPS_trackpoint_id) AS list_gps_points,
    array_length(array_agg(GPS_trackpoint_id),1) AS count_gps_points,
    ST_AsEWKT(ST_MakeLine(the_geom)) AS segment          
    FROM                        
      (                       
      SELECT photos.session_id AS session_id, 
      gps_tracks.fid AS GPS_trackpoint_id, 
      photos."FileName", gps_tracks.the_geom                       
      FROM photos_exif_core_metadata photos, gps_tracks                        
      WHERE 
        (gps_tracks."time"=(photos."DateTimeOriginal" - interval '7323 second') OR gps_tracks."time"=(photos."DateTimeOriginal" - interval '7322 second'))                       
        AND gps_tracks.session_id=photos.session_id 
        AND photos.session_id='session_2018_08_05_kite_Le_Morne'                        
      ) AS foo
    GROUP BY session_id, "FileName"
    ORDER BY session_id, "FileName") AS the_query 
WHERE    count_gps_points < 2 OR count_gps_points > 2
GROUP BY  session_id, list_gps_points, count_gps_points, segment 
ORDER BY  session_id, list_gps_points   




-- GIVES THE DETAILS ABOUT A PHOTO WHICH HAS MORE THAN 2 GPS POINTS

      SELECT 
      gps_tracks.fid AS GPS_trackpoint_id, 
      gps_tracks.latitude, 
      gps_tracks.longitude, 
      gps_tracks.time, 
      photos.*
      FROM photos_exif_core_metadata photos, gps_tracks                        
      WHERE 
        (gps_tracks."time"=(photos."DateTimeOriginal" - interval '7323 second') OR gps_tracks."time"=(photos."DateTimeOriginal" - interval '7322 second'))                       
        AND gps_tracks.session_id=photos.session_id 
        AND photos.session_id='session_2018_08_05_kite_Le_Morne'  
        AND photos."FileName"='G0052118.JPG'
        
        
        "session_2018_08_05_kite_Le_Morne";"{G0047130.JPG}";1;"{636,635,637,634}";4;"SRID=4326;LINESTRING(57.3187882900238 -20.4656875133514,57.3187359668113 -20.4657309280859,57.3187882900238 -20.4656875133514,57.3187329769135 -20.4657334089279)"
"session_2018_08_05_kite_Le_Morne";"{G0047129.JPG}";1;"{637,636,635,634}";4;"SRID=4326;LINESTRING(57.3187882900238 -20.4656875133514,57.3187882900238 -20.4656875133514,57.3187359668113 -20.4657309280859,57.3187329769135 -20.4657334089279)"
"session_2018_08_05_kite_Le_Morne";"{G0048925.JPG}";1;"{1841,1839,1840,1842}";4;"SRID=4326;LINESTRING(57.3102189302444 -20.4785205125809,57.3102788925171 -20.4784744977951,57.3102281136556 -20.4785134652713,57.3102189302444 -20.4785205125809)"
"session_2018_08_05_kite_Le_Morne";"{G0050249.JPG}";1;"{2727,2728,2730,2729}";4;"SRID=4326;LINESTRING(57.3091675043106 -20.4812468290329,57.3091626859711 -20.4812580182881,57.3091460466385 -20.4812966585159,57.3091460466385 -20.4812966585159)"
"session_2018_08_05_kite_Le_Morne";"{G0051218.JPG}";1;"{3377,3378,3379,3380}";4;"SRID=4326;LINESTRING(57.3165466785431 -20.4737272262573,57.316526252832 -20.4737532544492,57.3165049552917 -20.4737803936005,57.3165049552917 -20.4737803936005)"
"session_2018_08_05_kite_Le_Morne";"{G0052118.JPG}";1;"{3984,3981,3982,3983}";4;"SRID=4326;LINESTRING(57.3278077840805 -20.4627747535706,57.3278479576111 -20.4627501964569,57.3278413223433 -20.4627542524366,57.3278077840805 -20.4627747535706)"
"session_2018_08_05_kite_Le_Morne";"{G0053922.JPG,G0053923.JPG}";2;"{5192,5193,5194,5195}";4;"SRID=4326;LINESTRING(57.3075348138809 -20.473895072937,57.3075469502484 -20.4738623981016,57.307547211647 -20.4738616943359,57.307547211647 -20.4738616943359)"
"session_2018_08_05_kite_Le_Morne";"{G0055272.JPG}";1;"{6098,6099,6100,6101}";4;"SRID=4326;LINESTRING(57.309136390686 -20.4725303649902,57.3091427623009 -20.4725235214039,57.3091557025909 -20.4725096225739,57.3091557025909 -20.4725096225739)"
"session_2018_08_05_kite_Le_Morne";"{G0055273.JPG}";1;"{6100,6101,6098,6099}";4;"SRID=4326;LINESTRING(57.3091557025909 -20.4725096225739,57.3091557025909 -20.4725096225739,57.309136390686 -20.4725303649902,57.3091427623009 -20.4725235214039)"
"session_2018_08_05_kite_Le_Morne";"{G0055713.JPG,G0055714.JPG}";2;"{6394,6395,6396,6397}";4;"SRID=4326;LINESTRING(57.3108924627304 -20.4726697206497,57.3109167814255 -20.4726250171661,57.3109167814255 -20.4726250171661,57.3109253013205 -20.4726158719577)"
"session_2018_08_05_kite_Le_Morne";"{G0055715.JPG}";1;"{6395,6396,6397,6398}";4;"SRID=4326;LINESTRING(57.3109167814255 -20.4726250171661,57.3109167814255 -20.4726250171661,57.3109253013205 -20.4726158719577,57.3109557628632 -20.4725831747055)"
.



SELECT 'DROP VIEW "' || table_name || '"";'   FROM information_schema.views WHERE table_name LIKE 'view_session%'
