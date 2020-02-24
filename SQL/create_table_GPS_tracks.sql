DROP TABLE IF EXISTS "public"."gps_tracks" CASCADE;

CREATE TABLE "public"."gps_tracks"(
    ogc_fid SERIAL NOT NULL,
    "session_id" character varying(254),
    "time" timestamp with time zone,
    latitude double precision,
    longitude double precision,
    altitude double precision,
    heart_rate double precision,
    the_geom geometry(Point,4326),
    CONSTRAINT gps_pkey PRIMARY KEY ("ogc_fid"),
    FOREIGN KEY ("session_id") REFERENCES "metadata" ("Identifier"),
    CONSTRAINT unique_identifier UNIQUE ("ogc_fid")
)
WITH (
  OIDS=FALSE
);

COMMENT ON TABLE gps_tracks IS 'Table containing the raw spatial data as delivered by devices (GPS, RTK...). According to settings, the frequency of data collection can differ. The current data structure is inherited from tcx files';
COMMENT ON COLUMN gps_tracks."ogc_fid" IS '"ogc_fid" ';
COMMENT ON COLUMN gps_tracks."session_id" IS '"session_id" ';
COMMENT ON COLUMN gps_tracks."time" IS '"time"';
COMMENT ON COLUMN gps_tracks."latitude" IS '"latitude"';
COMMENT ON COLUMN gps_tracks."longitude" IS '"longitude"';
COMMENT ON COLUMN gps_tracks."altitude" IS '"altitude" ';
COMMENT ON COLUMN gps_tracks."heart_rate" IS '"heart_rate"';
COMMENT ON COLUMN gps_tracks."the_geom" IS '"the_geom"';

--CREATE INDEX gps_tracks_geom_idx ON "gps_tracks" USING GIST (the_geom);
