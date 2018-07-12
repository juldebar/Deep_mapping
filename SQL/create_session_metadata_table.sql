
CREATE TABLE metadata
(
  session_number serial NOT NULL,
  id_session text,
  persistent_identifier text,
  related_sql_query text,
  related_view_name text,
  identifier text,
  title text,
  contacts_and_roles text,
  subject text,
  description text,
  date text, 
  dataset_type text,
  format text, 
  language text,
  relation text,
  spatial_coverage text,
  temporal_coverage text,
  rights text,
  source text,
  provenance text,
  supplemental_information text,
  database_table_name text,
  time_offset numeric(24,15),  

  CONSTRAINT metadata_pkey PRIMARY KEY (id_session),
  CONSTRAINT unique_identifier UNIQUE (identifier)
) 
WITH (
  OIDS=FALSE
);

SELECT AddGeometryColumn('public','metadata','geometry_session',4326,'POINT',2);
CREATE INDEX "metadata_geometry_session_geom_idx" ON "public"."metadata" USING GIST ("geometry_session");
--
ALTER TABLE metadata
  OWNER TO Reef_admin;
GRANT SELECT ON TABLEmetadata TO Reef_admin;
GRANT ALL ON TABLE metadata TO Reef_admin;
COMMENT ON TABLE metadata
  IS 'Table containing the metadata on all the datasets available in the database';

--https://docs.google.com/spreadsheets/d/1MLemH3IC8ezn5T1a1AYa5Wfa1s7h6Wz_ACpFY3NvyrM/edit?usp=sharing
