DROP TABLE IF EXISTS  "public"."gps_tracks" CASCADE;
CREATE TABLE "public"."gps_tracks"(
    fid serial NOT NULL,
    session_id character varying(254),
    "time" timestamp with time zone,
    latitude double precision,
    longitude double precision,
    altitude double precision,
    heart_rate double precision,
    the_geom geometry(Point,4326),
    CONSTRAINT activities_pk PRIMARY KEY (fid,session_id)
);
SET TIME ZONE 'UTC';
