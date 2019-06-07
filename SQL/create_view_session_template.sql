DROP VIEW IF EXISTS "view_session_2018_03_31_kite_Le_Morne";

CREATE OR REPLACE VIEW "view_session_2018_03_31_kite_Le_Morne" AS 



 SELECT 
    row_number() OVER () AS OID,
    gps_tracks.session_id,
    array_agg(gps_tracks.fid) AS list_gps_points,
    array_agg(gps_tracks."time") AS "time",
    min(gps_tracks."time") AS start_date,
    max(gps_tracks."time") AS end_date,
    (('start='::text || min(gps_tracks."time")::text) || ';end='::text) || max(gps_tracks."time")::text AS temporal_coverage,
    st_asewkt(st_makeline(gps_tracks.the_geom)) AS spatial_coverage,
    st_makeline(gps_tracks.the_geom) AS track
   FROM gps_tracks
  WHERE gps_tracks.session_id::text = 'session_2018_03_31_kite_Le_Morne'::text
  GROUP BY gps_tracks.session_id;





ALTER TABLE "view_session_2018_03_31_kite_Le_Morne"
  OWNER TO "Reef_admin";

