select * from gps_tracks where fid IN (939,940,941) and session_id='session_2018_03_31_kite_Le_Morne'
SELECT array_agg(gps_tracks.fid),time AS list_gps_points from gps_tracks  where session_id='session_2018_03_31_kite_Le_Morne' GROUP by time having count(*) > 1

