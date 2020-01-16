DROP TABLE IF EXISTS metadata CASCADE;

CREATE TABLE metadata
(
  session_number serial NOT NULL,
  session_id text,
  persistent_identifier text,
  related_sql_query text,
  related_view_name text,
  identifier text,
  title text,
  contacts_and_roles text,
  subject text,
  description text,
  date text, 
  type text,
  format text, 
  language text,
  relation text,
  spatial_coverage text,
  temporal_coverage text,
  rights text,
  source text,
  provenance text,
  time_offset numeric(24,15),  

  CONSTRAINT metadata_pkey PRIMARY KEY (session_id),
  CONSTRAINT unique_identifier UNIQUE (identifier)
) 
WITH (
  OIDS=FALSE
);

SELECT AddGeometryColumn('public','metadata','geometry_session',4326,'GEOMETRY',2);
CREATE INDEX "metadata_geometry_session_geom_idx" ON "public"."metadata" USING GIST ("geometry_session");
--
ALTER TABLE metadata
  OWNER TO Reef_admin;
GRANT SELECT ON TABLEmetadata TO Reef_admin;
GRANT ALL ON TABLE metadata TO Reef_admin;
COMMENT ON TABLE metadata IS 'Table containing the metadata on all the datasets available in the database';
COMMENT ON COLUMN metadata.session_number IS 'internal identifier for a session in this table and database';
COMMENT ON COLUMN metadata.session_id IS 'session identifier complying with a naming convention';
COMMENT ON COLUMN metadata.persistent_identifier IS 'when a dataset has multiple versions (eg yearly versions) the persistent identifier is for the last version (up to date)';
COMMENT ON COLUMN metadata.related_sql_query IS 'the SQL query to be executed to get this dataset';
COMMENT ON COLUMN metadata.related_view_name IS 'the name of the view to directly access this dataset (if it exists)';
COMMENT ON COLUMN metadata.identifier IS 'identifier" metadata element of the metadata_sheet';
COMMENT ON COLUMN metadata.title IS '"title" metadata element as defined by Dublin Core Metadata Initiative';
COMMENT ON COLUMN metadata.contacts_and_roles IS 'customized field includes all contacts as defined by Dublin Core Metadata Initiative (Creator , ….)';
COMMENT ON COLUMN metadata.subject IS '"subject" metadata element as defined by Dublin Core Metadata Initiative';
COMMENT ON COLUMN metadata.description IS '"description" metadata element as defined by Dublin Core Metadata Initiative';
COMMENT ON COLUMN metadata.date IS '"date" metadata element as defined by Dublin Core Metadata Initiative';
COMMENT ON COLUMN metadata.type IS '"type" metadata element as defined by Dublin Core Metadata Initiative';
COMMENT ON COLUMN metadata.format IS '"format" metadata element as defined by Dublin Core Metadata Initiative';
COMMENT ON COLUMN metadata.language IS '"language" metadata element as defined by Dublin Core Metadata Initiative';
COMMENT ON COLUMN metadata.relation IS '"relation" metadata element as defined by Dublin Core Metadata Initiative';
COMMENT ON COLUMN metadata.spatial_coverage IS '"spatial" metadata element as defined by Dublin Core Metadata Initiative (which refines coverage)';
COMMENT ON COLUMN metadata.temporal_coverage IS '"temporal" metadata element as defined by Dublin Core Metadata Initiative (which refines coverage)';
COMMENT ON COLUMN metadata.rights IS '"rights" metadata element as defined by Dublin Core Metadata Initiative';
COMMENT ON COLUMN metadata.source IS '"source" metadata element  as defined by Dublin Core Metadata Initiative';
COMMENT ON COLUMN metadata.provenance IS '"provenance" metadata element as defined by Dublin Core Metadata Initiative';
COMMENT ON COLUMN metadata.time_offset IS '"time_offset" stores the time offset between the time given by GPS and the time given by the camera taking photos';
COMMENT ON COLUMN metadata.geometry_session IS '"geometry_session" stores the spatial geometry of track points collected by GPS during the session';

--https://docs.google.com/spreadsheets/d/1MLemH3IC8ezn5T1a1AYa5Wfa1s7h6Wz_ACpFY3NvyrM/edit?usp=sharing
