DROP TABLE IF EXISTS "public"."photos_exif_core_metadata" CASCADE;

CREATE TABLE "public"."photos_exif_core_metadata" ("photo_id" SERIAL NOT NULL, CONSTRAINT "photos_exif_core_metadata_pk" PRIMARY KEY ("photo_id"));

ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "session_id" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "session_photo_number" integer;
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "relative_path" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "FileName" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "FileSize" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "FileType" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "DateTimeOriginal" timestamp with time zone ;
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "Make" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "Model" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "LightValue" NUMERIC(24,15);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "ImageSize" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "ExifToolVersion" VARCHAR(254);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "GPSLatitude" NUMERIC(24,15);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "GPSLongitude" NUMERIC(24,15);
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "GPSDateTime" timestamp with time zone;
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "ThumbnailImage" TEXT;
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "ThumbnailOffset" integer;
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "ThumbnailLength" integer;
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "PreviewImage" TEXT;
ALTER TABLE "public"."photos_exif_core_metadata" ADD COLUMN "URL_original_image" TEXT;

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
COMMENT ON COLUMN photos_exif_core_metadata."GPSLatitude" IS '"GPSLatitude: Indicates the latitude. The latitude is expressed as three RATIONAL values giving the degrees, minutes, and seconds, respectively. When degrees, minutes and seconds are expressed, the format is dd/1,mm/1,ss/1. When degrees and minutes are used and, for example, fractions of minutes are given up to two decimal places, the format is dd/1,mmmm/100,0/1."';
COMMENT ON COLUMN photos_exif_core_metadata."GPSLongitude" IS '"GPSLongitude:Indicates the longitude. The longitude is expressed as three RATIONAL values giving the degrees, minutes, and seconds, respectively. When degrees, minutes and seconds are expressed, the format is ddd/1,mm/1,ss/1. When degrees and minutes are used and, for example, fractions of minutes are given up to two decimal places, the format is ddd/1,mmmm/100,0/1." ';
COMMENT ON COLUMN photos_exif_core_metadata."GPSDateTime" IS '"GPSDateTime"';
COMMENT ON COLUMN photos_exif_core_metadata."DateTimeOriginal" IS '"DateTimeOriginal:The date and time when the original image data was generated."';
COMMENT ON COLUMN photos_exif_core_metadata."LightValue" IS '"LightValue"';
COMMENT ON COLUMN photos_exif_core_metadata."ImageSize" IS '"ImageSize": Exif.Image.ImageWidth	et Exif.Image.ImageLength ???';
COMMENT ON COLUMN photos_exif_core_metadata."Model" IS '"Model: The model name or model number of the equipment. This is the model name or number of the DSC, scanner, video digitizer or other equipment that generated the image. When the field is left blank, it is treated as unknown."';
COMMENT ON COLUMN photos_exif_core_metadata."ThumbnailImage" IS '"ThumbnailImage" ';
COMMENT ON COLUMN photos_exif_core_metadata."PreviewImage" IS '"PreviewImage"';
COMMENT ON COLUMN photos_exif_core_metadata."geometry_postgis" IS '"geometry_postgis"';
COMMENT ON COLUMN photos_exif_core_metadata."geometry_gps_correlate" IS '"geometry_gps_correlate"';
COMMENT ON COLUMN photos_exif_core_metadata."geometry_native" IS '"geometry_native"';


--"SourceFile","ExifToolVersion","FileName","Directory","FileSize","FileModifyDate","FileAccessDate","FileInodeChangeDate","FilePermissions","FileType","FileTypeExtension","MIMEType","ExifByteOrder","ImageDescription","Make","Model","Orientation","XResolution","YResolution","ResolutionUnit","Software","ModifyDate","YCbCrPositioning","ExposureTime","FNumber","ExposureProgram","ISO","ExifVersion","DateTimeOriginal","CreateDate","ComponentsConfiguration","CompressedBitsPerPixel","ShutterSpeedValue","ApertureValue","ExposureCompensation","MaxApertureValue","SubjectDistance","MeteringMode","LightSource","Flash","FocalLength","Warning","FlashpixVersion","ColorSpace","ExifImageWidth","ExifImageHeight","InteropIndex","InteropVersion","ExposureIndex","SensingMethod","FileSource","SceneType","CustomRendered","ExposureMode","WhiteBalance","DigitalZoomRatio","FocalLengthIn35mmFormat","SceneCaptureType","GainControl","Contrast","Saturation","Sharpness","DeviceSettingDescription","SubjectDistanceRange","SerialNumber","GPSVersionID","GPSLatitudeRef","GPSLongitudeRef","GPSAltitudeRef","GPSTimeStamp","GPSMapDatum","GPSDateStamp","Compression","ThumbnailOffset","ThumbnailLength","MPFVersion","NumberOfImages","MPImageFlags","MPImageFormat","MPImageType","MPImageLength","MPImageStart","DependentImage1EntryNumber","DependentImage2EntryNumber","ImageUIDList","TotalFrames","ImageWidth","ImageHeight","EncodingProcess","BitsPerSample","ColorComponents","YCbCrSubSampling","Aperture","GPSAltitude","GPSDateTime","GPSLatitude","GPSLongitude","GPSPosition","ImageSize","PreviewImage","Megapixels","ScaleFactor35efl","ShutterSpeed","ThumbnailImage","CircleOfConfusion","FOV","FocalLength35efl","HyperfocalDistance","LightValue" 
--"ComponentsConfiguration",
--"CompressedBitsPerPixel",
--"ShutterSpeedValue",
--"ApertureValue",
--"ExposureCompensation",
--"MaxApertureValue",
--"SubjectDistance",
--"MeteringMode",
--"LightSource",
--"Flash",
--"FocalLength",
--"Warning",
--"FlashpixVersion",
--"ColorSpace",
--"ExifImageWidth",
--"ExifImageHeight",
--"InteropIndex",
--"InteropVersion",
--"ExposureIndex",
--"SensingMethod",
--"FileSource",
--"SceneType",
--"CustomRendered",
--"ExposureMode",
--"WhiteBalance",
--"DigitalZoomRatio",
--"FocalLengthIn35mmFormat",
--"SceneCaptureType",
--"GainControl",
--"Contrast",
--"Saturation",
--"Sharpness",
--"DeviceSettingDescription",
--"SubjectDistanceRange",
--"SerialNumber",
--"GPSVersionID",
--"GPSLatitudeRef",
--"GPSLongitudeRef",
--"GPSAltitudeRef",
--"GPSTimeStamp",
--"GPSMapDatum",
--"GPSDateStamp",
--"Compression",
--"ThumbnailOffset",
--"ThumbnailLength",
--"MPFVersion",
--"NumberOfImages",
--"MPImageFlags",
--"MPImageFormat",
--"MPImageType",
--"MPImageLength",
--"MPImageStart",
--"DependentImage1EntryNumber",
--"DependentImage2EntryNumber",
--"ImageUIDList",
--"TotalFrames",
--"ImageWidth",
--"ImageHeight",
--"EncodingProcess",
--"BitsPerSample",
--"ColorComponents",
--"YCbCrSubSampling",
--"Aperture",
--"GPSAltitude",
--"GPSDateTime",
--"GPSLatitude",
--"GPSLongitude",
--"GPSPosition",
--"ImageSize",
--"PreviewImage",
--"Megapixels",
--"ScaleFactor35efl",
--"ShutterSpeed",
--"ThumbnailImage",
--"CircleOfConfusion",
--"FOV",
--"FocalLength35efl",
--"HyperfocalDistance",
--"LightValue"
