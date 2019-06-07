DROP TABLE IF EXISTS  "public"."photos_exif_core_metadata" CASCADE;

CREATE TABLE "public"."photos_exif_core_metadata" ("ogc_fid" SERIAL, CONSTRAINT "photos_exif_core_metadata_pk" PRIMARY KEY ("ogc_fid") );

ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "session_id" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "session_photo_number" integer;
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "relative_path" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "FileName" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "GPSLatitude" NUMERIC(24,15);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "GPSLongitude" NUMERIC(24,15);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "GPSDateTime" timestamp with time zone;
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "DateTimeOriginal" timestamp with time zone ;
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "LightValue" NUMERIC(24,15);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "ImageSize" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "Model" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "ThumbnailImage" TEXT;
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "PreviewImage" TEXT;


SELECT AddGeometryColumn('public','photos_exif_core_metadata','geometry_postgis',4326,'POINT',2);
SELECT AddGeometryColumn('public','photos_exif_core_metadata','geometry_gps_correlate',4326,'POINT',2);
SELECT AddGeometryColumn('public','photos_exif_core_metadata','geometry_native',4326,'POINT',2);
CREATE INDEX "photos_exif_core_metadata_geometry_postgis_geom_idx" ON "public"."photos_exif_core_metadata" USING GIST ("geometry_postgis");
CREATE INDEX "photos_exif_core_metadata_geometry_gps_correlate_geom_idx" ON "public"."photos_exif_core_metadata" USING GIST ("geometry_gps_correlate");
CREATE INDEX "photos_exif_core_metadata_geometry_native_geom_idx" ON "public"."photos_exif_core_metadata" USING GIST ("geometry_native");

SET TIME ZONE 'UTC';
-- add foreign key constraint

--show timezone;

