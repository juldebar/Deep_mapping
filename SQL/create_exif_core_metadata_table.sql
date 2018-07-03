CREATE TABLE "public"."photos_exif_core_metadata" ("ogc_fid" SERIAL, CONSTRAINT "photos_exif_core_metadata_pk" PRIMARY KEY ("ogc_fid") );

ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "session_id" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "filename" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "gpslatitud" NUMERIC(24,15);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "gpslongitu" NUMERIC(24,15);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "gpsdatetim" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "datetimeor" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "lightvalue" NUMERIC(24,15);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "imagesize" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "model" VARCHAR(254);

SELECT AddGeometryColumn('public','photos_exif_core_metadata','geometry_postgis',4326,'POINT',2);
SELECT AddGeometryColumn('public','photos_exif_core_metadata','geometry_gps_correlate',4326,'POINT',2);
SELECT AddGeometryColumn('public','photos_exif_core_metadata','geometry_native',4326,'POINT',2);
CREATE INDEX "photos_exif_core_metadata_geometry_postgis_geom_idx" ON "public"."photos_exif_core_metadata" USING GIST ("geometry_postgis");
CREATE INDEX "photos_exif_core_metadata_geometry_gps_correlate_geom_idx" ON "public"."photos_exif_core_metadata" USING GIST ("geometry_gps_correlate");
CREATE INDEX "photos_exif_core_metadata_geometry_native_geom_idx" ON "public"."photos_exif_core_metadata" USING GIST ("geometry_native");
