UPDATE metadata SET geometry_session =  toto.track FROM  
(SELECT session_id, ST_MakeLine(the_geom) AS track FROM  gps_tracks  GROUP BY session_id) AS toto 
WHERE  metadata.session_id=toto.session_id ;


UPDATE metadata SET temporal_coverage =  toto.temporal_coverage FROM  
(SELECT session_id, 'start='::text || MIN(gps_tracks.time)::text || ';end='::text ||MAX(gps_tracks.time)::text AS temporal_coverage FROM  gps_tracks  GROUP BY session_id) 
AS toto 
WHERE metadata.session_id=toto.session_id ;


UPDATE metadata SET spatial_coverage =  Wkt_bounding_box FROM  
(SELECT session_id, ST_AsText(ST_Envelope(ST_ConvexHull(ST_MakeLine(the_geom)))) AS Wkt_bounding_box FROM  gps_tracks  GROUP BY session_id) 
AS toto 
WHERE  metadata.session_id=toto.session_id ;
