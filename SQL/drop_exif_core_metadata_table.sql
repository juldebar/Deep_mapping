SET standard_conforming_strings = OFF;
DROP TABLE IF EXISTS "public"."photos_exif_core_metadata" CASCADE;
DELETE FROM geometry_columns WHERE f_table_name = 'photos_exif_core_metadata' AND f_table_schema = 'public';
