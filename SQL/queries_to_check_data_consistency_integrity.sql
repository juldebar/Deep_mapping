select * from gps_tracks where fid IN (939,940,941) and session_id='session_2018_03_31_kite_Le_Morne'
SELECT array_agg(gps_tracks.fid),time AS list_gps_points from gps_tracks  where session_id='session_2018_03_31_kite_Le_Morne' GROUP by time having count(*) > 1

SELECT session_id, array_agg(gps_tracks.fid) AS list_gps_points, array_agg(gps_tracks.time) AS time, ST_AsEWKT(ST_MakeLine(the_geom)) AS WKT, ST_MakeLine(the_geom) AS track from gps_tracks  where session_id='session_2018_03_31_kite_Le_Morne' GROUP by session_id;




--system("ogr2ogr -f GPX  -dsco GPX_USE_EXTENSIONS=YES points.gpx PG:'host=reef-db.d4science.org user=Reef_admin password=4b0a6dd24ac7b79 dbname=Reef_database' track_points -nlt POINT -sql \"select * from test_view \" ")

