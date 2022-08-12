SELECT COUNT(taxonID), taxonID, scientificName FROM 
(SELECT 
    --row_number() OVER () AS line_number,
   'MachineObservation' AS "basisOfRecord",
    CONCAT('https://julien.oreme.org/Deep_mapping/'||(photos.session_id::text || '_'::text) || photos."FileName"::text) AS "associatedMedia",   
    photos.session_id AS datasetName,
    photos.session_id AS datasetID,
    --photos.photo_id AS id,
    concat((photos.session_id::text || '_'::text) || photos."FileName"::text) AS file_name,
    --concat((photos.relative_path::text || '/'::text) || photos."FileName"::text) AS relative_path,
    label.tag_label AS taxonID,
    label.tag_label AS scientificName,
    'present' AS occurrenceStatus,    
    1 AS individualCount,    
    'julien.barde@ird.fr' AS "identifiedBy",
    'Coral_reef' AS habitat,
    photos."DateTimeOriginal" AS "eventTime",
    photos."GPSDateTime" AS eventDate,
    photos."GPSLatitude" AS "decimalLatitude",
    photos."GPSLongitude" AS "decimalLongitude",
    st_astext(photos.geometry_postgis) AS "footprintWKT",
    5 AS "coordinateUncertaintyInMeters",
    0 AS "verbatimElevation",
    0 AS "verbatimDepth",
    'WGS84' AS "footprintSRS",
    'GPS' AS georeferenceProtocol,
    photos."Make",
    photos."Model",
    SPLIT_PART(photos."ImageSize", ' ', 1) AS width,
    SPLIT_PART(photos."ImageSize", ' ', 2) AS height,
    photos."LightValue"        
--    ,photos."ThumbnailImage"
   FROM photos_exif_core_metadata photos,
    annotation,
    label
  WHERE photos.photo_id = annotation.photo_id AND label.tag_id = annotation.tag_id
  ORDER BY photos.session_id, label
) AS foo
GROUP BY taxonID, scientificName 
ORDER BY count DESC
--  LIMIT 1000

