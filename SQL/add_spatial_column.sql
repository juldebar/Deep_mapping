UPDATE gps_tracks SET the_geom = ST_SetSRID(st_makepoint(longitude, latitude),4326);
DROP INDEX IF EXISTS gps_tracks_geom_idx;
CREATE INDEX gps_tracks_geom_idx ON "gps_tracks" USING GIST (the_geom);
-- UPDATE gps_tracks SET the_geom = ST_GeomFromText('POINT ('::text || longitude	::text || ' '::text ||latitude::text || ')'::text, 4326) "
--	SELECT AddGeometryColumn ('public','gps_tracks','the_geom',4326,'POINT',2);
