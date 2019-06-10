DROP TABLE metadata;

CREATE TABLE metadata
(
  id_session serial NOT NULL, -- internal identifier for the session / deployment / set of images
  persistent_identifier text, -- when a dataset has multiple versions (eg yearly versions) the    persistent identifier is for the last version (up to date)
  related_sql_query text, --  the SQL query to be executed to get this dataset
  related_view_name text, -- the name of the view to directly access this dataset (if it exists)
  identifier text, -- identifier of the metadata_sheet
  title text, -- title as defined by Dublin Core Metadata Initiative
  contacts_and_roles text,  --  customized field includes all contacts as defined by Dublin Core Metadata Initiative (Creator , ….)
  subject text, -- subject as defined by Dublin Core Metadata Initiative
  description text, -- description as defined by Dublin Core Metadata Initiative
  date text, -- date as defined by Dublin Core Metadata Initiative
  dataset_type text, -- type as defined by Dublin Core Metadata Initiative
  format text, -- format  as defined by Dublin Core Metadata Initiative
  language text, -- language as defined by Dublin Core Metadata Initiative
  relation text, -- relation as defined by Dublin Core Metadata Initiative
  spatial_coverage text, -- spatial as defined by Dublin Core Metadata Initiative (which refines coverage)
  temporal_coverage text, -- temporal as defined by Dublin Core Metadata Initiative (which refines coverage)
  rights text, -- rights as defined by Dublin Core Metadata Initiative
  source text, -- source  as defined by Dublin Core Metadata Initiative
  provenance text, -- provenance as defined by Dublin Core Metadata Initiative
  supplemental_information text, -- additional comments ?
  database_table_name text, -- inutile ?
  offset numeric(24,15)  -- Offset between the time of camera taking underwater pictures and the time given by the GPS

  CONSTRAINT metadata_pkey PRIMARY KEY (id_dataset),
  CONSTRAINT unique_identifier UNIQUE (identifier)
)
WITH (
  OIDS=FALSE
);

SELECT AddGeometryColumn('public','metadata','geometry_session',4326,'POINT',2);
CREATE INDEX "metadata_geometry_session_geom_idx" ON "public"."metadata" USING GIST ("geometry_session");

ALTER TABLE metadata
  OWNER TO invRTTP;
GRANT SELECT ON TABLEmetadata TO invRTTP;
GRANT ALL ON TABLE metadata TO invRTTP;
COMMENT ON TABLE metadata
  IS 'Table containing the metadata on all the datasets available in the database';

--https://docs.google.com/spreadsheets/d/1MLemH3IC8ezn5T1a1AYa5Wfa1s7h6Wz_ACpFY3NvyrM/edit?usp=sharing
