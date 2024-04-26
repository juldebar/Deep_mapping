DROP MATERIALIZED VIEW IF EXISTS "view_ID_SESSION" CASCADE;
DROP TABLE IF EXISTS "ID_SESSION" CASCADE ;
DELETE FROM public.photos_exif_core_metadata WHERE session_id = 'ID_SESSION' ;
DELETE FROM public.gps_tracks WHERE session_id = 'ID_SESSION' ;
DELETE FROM public.metadata WHERE "Identifier" = 'ID_SESSION'

