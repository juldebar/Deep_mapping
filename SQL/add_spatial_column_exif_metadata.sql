UPDATE photos_exif_core_metadata SET geometry_native = ST_SetSRID(st_makepoint("GPSLongitude", "GPSLatitude"),4326) WHERE session_id LIKE 'session%';;
--DROP INDEX IF EXISTS photos_exif_core_metadata_geometry_native_geom_idx;
--CREATE INDEX photos_exif_core_metadata_geometry_native_geom_idx ON "photos_exif_core_metadata" USING GIST (geometry_native);
