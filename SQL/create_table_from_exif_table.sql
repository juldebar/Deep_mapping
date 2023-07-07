DROP TABLE IF EXISTS public."replace_session_id" CASCADE ;

CREATE TABLE "replace_session_id" AS 
	SELECT
		photo_id,
		session_id,
		session_id AS "datasetID",
		session_photo_number,
		relative_path AS photo_relative_file_path,
		"GPSLatitude" AS "decimalLatitude",
		"GPSLongitude" AS "decimalLongitude",
		"DateTimeOriginal" AS "GPSDateTime",
		"DateTimeOriginal",
		"LightValue",
		"ImageSize",
		"Make",
		"Model",
		"ThumbnailImage",
		"PreviewImage",
		"URL_original_image",
		geometry_native AS "the_geom"
	FROM 
		"photos_exif_core_metadata"
	WHERE 
		"photos_exif_core_metadata".session_id='replace_session_id';

ALTER TABLE "replace_session_id" ADD PRIMARY KEY ("photo_id");  


COMMENT ON TABLE "replace_session_id" IS 'Table containing the main attributes for all pictures of a session including an estimated position inferred from GPS tracks';

COMMENT ON COLUMN "replace_session_id"."datasetID" IS '"datasetID  (as defined by Darwin Core standard data structure: https://github.com/tdwg/dwc/blob/master/vocabulary/term_versions.csv):"An identifier for the set of data. May be a global unique identifier or an identifier specific to a collection or institution."';
COMMENT ON COLUMN "replace_session_id"."decimalLatitude" IS '"decimalLatitude (as defined by Darwin Core standard data structure: https://github.com/tdwg/dwc/blob/master/vocabulary/term_versions.csv):"The geographic latitude (in decimal degrees, using the spatial reference system given in geodeticDatum) of the geographic center of a Location. Positive values are north of the Equator, negative values are south of it. Legal values lie between -90 and 90, inclusive.';
COMMENT ON COLUMN "replace_session_id"."decimalLongitude" IS '"decimalLatitude (as defined by Darwin Core standard data structure: https://github.com/tdwg/dwc/blob/master/vocabulary/term_versions.csv):"The geographic longitude (in decimal degrees, using the spatial reference system given in geodeticDatum) of the geographic center of a Location. Positive values are east of the Greenwich Meridian, negative values are west of it. Legal values lie between -180 and 180, inclusive.';

-- COMMENT ON COLUMN "replace_session_id"."footprintWKT" IS '"footprintWKT: A Well-Known Text (WKT) representation of the shape (footprint, geometry) that defines the Location. A Location may have both a point-radius representation (see decimalLatitude) and a footprint representation, and they may differ from each other.';



-- https://github.com/tdwg/dwc/blob/master/vocabulary/term_versions.csv
--		"tag_id" AS "taxonID",
--COMMENT ON COLUMN "replace_session_id"."recordedBy" IS '"recordedBy:A list (concatenated and separated) of names of people, groups, or organizations responsible for recording the original Occurrence. The primary collector or observer, especially one who applies a personal identifier (recordNumber), should be listed first.';

--		"GPSLatitude"|| "GPSLongitude" AS "footprintWKT",
-- 	"footprintWKT",
