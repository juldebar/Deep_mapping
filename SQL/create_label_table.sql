DROP TABLE IF EXISTS  "public"."label" CASCADE;

CREATE TABLE "public"."label" (
	"tag_id" SERIAL,
	CONSTRAINT "label_pk" PRIMARY KEY ("tag_id")
	);

ALTER TABLE "public"."label" ADD COLUMN "tag_code" VARCHAR(254);
ALTER TABLE "public"."label" ADD COLUMN "tag_label" VARCHAR(254);
ALTER TABLE "public"."label" ADD COLUMN "tag_definition" VARCHAR(254);

COMMENT ON TABLE "label" IS 'Table storing some of the numerous exif metadata element which are extracted from pictures headers (using exifr R package)';
COMMENT ON COLUMN "label"."tag_id" IS '"tag_id" ';
COMMENT ON COLUMN "label"."tag_label" IS '"tag_label" ';
COMMENT ON COLUMN "label"."tag_definition" IS '"tag_definition" ';

DROP TABLE IF EXISTS  "public"."annotation" CASCADE;

CREATE TABLE "public"."annotation" (
	"photo_id" INTEGER,
	"tag_id" INTEGER,
	PRIMARY KEY (photo_id, tag_id),
	FOREIGN KEY ("tag_id") REFERENCES "label" ("tag_id"),
	FOREIGN KEY ("photo_id") REFERENCES "photos_exif_core_metadata" ("photo_id")
	);

COMMENT ON TABLE "annotation" IS 'Table storing some of the numerous exif metadata element which are extracted from pictures headers (using exifr R package)';
COMMENT ON COLUMN "annotation"."tag_id" IS '"tag_id" ';
COMMENT ON COLUMN "annotation"."photo_id" IS '"photo_id" ';


