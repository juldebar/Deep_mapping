DROP TABLE IF EXISTS "public"."metadata" CASCADE;

CREATE TABLE metadata
(
  "id_metadata" serial NOT NULL,
  "Identifier" text,
  "Description" text,
  "Title" text,
  "Subject" text,
  "Creator" text,
  "Date" text, 
  "Type" text,
  "SpatialCoverage" text,
  "TemporalCoverage" text,
  "Language" text,
  "Relation" text,
  "Rights" text,
  "Source" text,
  "Provenance" text,
  "Format" text, 
  "Data" text,
  "path" text,
  "gps_file_name" text,
  "Number_of_Pictures" text,
  "GPS_timestamp" text,
  "Photo_GPS_timestamp" text,
  CONSTRAINT metadata_pkey PRIMARY KEY ("Identifier"),
  CONSTRAINT unique_identifier UNIQUE ("Identifier")
) 
WITH (
  OIDS=FALSE
);

SELECT AddGeometryColumn('public','metadata','geometry',4326,'GEOMETRY',2);
CREATE INDEX "metadata_geometry_session_geom_idx" ON "public"."metadata" USING GIST ("geometry");
ALTER TABLE metadata OWNER TO Reef_admin;
GRANT SELECT ON TABLE metadata TO Reef_admin;
GRANT ALL ON TABLE metadata TO Reef_admin;

COMMENT ON TABLE metadata IS 'Table containing the metadata on all the datasets available in the database using DCMI Metadata Terms (https://www.dublincore.org/specifications/dublin-core/dcmi-terms)';
COMMENT ON COLUMN metadata."Identifier" IS '"Identifier" metadata element as defined by DCMI: An unambiguous reference to the resource within a given context (eg session_id for input datasets)';
COMMENT ON COLUMN metadata."Description" IS '"Description" metadata element as defined by DCMI: An account of the resource.';
COMMENT ON COLUMN metadata."Title" IS '"Title" metadata element as defined by DCMI: A name given to the resource.';
COMMENT ON COLUMN metadata."Subject" IS '"Subject" metadata element as defined by DCMI: The topic of the resource.';
COMMENT ON COLUMN metadata."Creator" IS 'customized field includes all contacts as defined by DCMI: (Creator,contributor, publisher...)';
COMMENT ON COLUMN metadata."Date" IS '"Date" metadata element as defined by DCMI: A point or period of time associated with an event in the lifecycle of the resource.';
COMMENT ON COLUMN metadata."Type" IS '"Type" metadata element as defined by DCMI: The nature or genre of the resource.';
COMMENT ON COLUMN metadata."SpatialCoverage" IS '"SpatialCoverage" metadata element as defined by DCMI: Spatial characteristics of the resource (which refines coverage)';
COMMENT ON COLUMN metadata."TemporalCoverage" IS '"TemporalCoverage" metadata element as defined by DCMI: Temporal characteristics of the resource (which refines coverage)';
COMMENT ON COLUMN metadata."Language" IS '"Language" metadata element as defined by DCMI: A language of the resource.';
COMMENT ON COLUMN metadata."Relation" IS '"Relation" metadata element as defined by DCMI: A related resource.';
COMMENT ON COLUMN metadata."Rights" IS '"Rights" metadata element as defined by DCMI: Information about rights held in and over the resource.';
COMMENT ON COLUMN metadata."Source" IS '"Source" metadata element as defined by DCMI: A related resource from which the described resource is derived.';
COMMENT ON COLUMN metadata."Provenance" IS '"Provenance" metadata element as defined by DCMI: A statement of any changes in ownership and custody of the resource since its creation that are significant for its authenticity, integrity, and interpretation.';
COMMENT ON COLUMN metadata."Format" IS '"Format" metadata element as defined by DCMI: The file format, physical medium, or dimensions of the resource.';
COMMENT ON COLUMN metadata."Data" IS '"Data" metadata element:';
COMMENT ON COLUMN metadata."geometry" IS '"geometry" metadata element stores a spatial geometry representing the dataset (eg a set of track points collected by the GPS during the session)';
--# Identifier	Title	Description	Subject	Creator	Date	Type	Language	SpatialCoverage	TemporalCoverage	Relation	Rights	Provenance	Data	path	gps_file_name	Number_of_Pictures	GPS_timestamp	Photo_GPS_timestamp

 -- internal identifier for the session / deployment / set of images
--  "session_id" text,
--  "time_offset" numeric(24,15),  
--  "session_number" serial NOT NULL,
--  "persistent_identifier" text,
--  "related_sql_query" text, => replaced by Data
--  "related_view_name" text, => replaced by Data

--  COMMENT ON COLUMN metadata."session_id" IS 'session identifier complying with a naming convention';
--  COMMENT ON COLUMN metadata."time_offset" IS '"time_offset" stores the time offset between the time given by GPS and the time given by the camera taking photos';
--  COMMENT ON COLUMN metadata."session_number" IS 'internal identifier for a session in this table and database';
--  COMMENT ON COLUMN metadata."persistent_identifier" IS 'when a dataset has multiple versions (eg yearly versions) the persistent identifier is for the last version (up to date)';
--  COMMENT ON COLUMN metadata."related_sql_query" IS 'the SQL query to be executed to get this dataset';
--  COMMENT ON COLUMN metadata."related_view_name" IS 'the name of the view to directly access this dataset (if it exists)';
--  https://docs.google.com/spreadsheets/d/1MLemH3IC8ezn5T1a1AYa5Wfa1s7h6Wz_ACpFY3NvyrM/edit?usp=sharing
