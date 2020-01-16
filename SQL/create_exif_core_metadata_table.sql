DROP TABLE IF EXISTS "public"."photos_exif_core_metadata" CASCADE;

CREATE TABLE "public"."photos_exif_core_metadata" ("photo_id" SERIAL, CONSTRAINT "photos_exif_core_metadata_pk" PRIMARY KEY ("photo_id"));

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

COMMENT ON TABLE photos_exif_core_metadata IS 'Table storing some of the numerous exif metadata element which are extracted from pictures headers (using exifr R package)';
COMMENT ON COLUMN photos_exif_core_metadata."photo_id" IS '"photo_id" ';
COMMENT ON COLUMN photos_exif_core_metadata."session_id" IS '"session_id" ';
COMMENT ON COLUMN photos_exif_core_metadata."session_photo_number" IS '"session_photo_number"';
COMMENT ON COLUMN photos_exif_core_metadata."relative_path" IS '"relative_path"';
COMMENT ON COLUMN photos_exif_core_metadata."FileName" IS '"FileName"';
COMMENT ON COLUMN photos_exif_core_metadata."GPSLatitude" IS '"GPSLatitude"';
COMMENT ON COLUMN photos_exif_core_metadata."GPSLongitude" IS '"GPSLongitude" ';
COMMENT ON COLUMN photos_exif_core_metadata."GPSDateTime" IS '"GPSDateTime"';
COMMENT ON COLUMN photos_exif_core_metadata."DateTimeOriginal" IS '"DateTimeOriginal"';
COMMENT ON COLUMN photos_exif_core_metadata."LightValue" IS '"LightValue"';
COMMENT ON COLUMN photos_exif_core_metadata."ImageSize" IS '"ImageSize"';
COMMENT ON COLUMN photos_exif_core_metadata."Model" IS '"Model"';
COMMENT ON COLUMN photos_exif_core_metadata."ThumbnailImage" IS '"ThumbnailImage" ';
COMMENT ON COLUMN photos_exif_core_metadata."PreviewImage" IS '"PreviewImage"';
COMMENT ON COLUMN photos_exif_core_metadata."geometry_postgis" IS '"geometry_postgis"';
COMMENT ON COLUMN photos_exif_core_metadata."geometry_gps_correlate" IS '"geometry_gps_correlate"';
COMMENT ON COLUMN photos_exif_core_metadata."geometry_native" IS '"geometry_native"';
