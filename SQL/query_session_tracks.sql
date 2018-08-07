SELECT 
session_id, 
array_agg(gps_tracks.fid) AS list_gps_points, 
array_agg(gps_tracks.time) AS time, 
min(gps_tracks.time) AS start_date, 
max(gps_tracks.time) AS end_date, 
'start='::text || MIN(gps_tracks.time)::text || ';end='::text ||MAX(gps_tracks.time)::text AS temporal_coverage,
ST_AsEWKT(ST_MakeLine(the_geom)) AS spatial_coverage, 
ST_MakeLine(the_geom) AS track 
FROM 
 gps_tracks  
WHERE 
session_id='session_2018_03_31_kite_Le_Morne' 
GROUP BY 
session_id;
