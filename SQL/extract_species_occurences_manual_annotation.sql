DROP MATERIALIZED VIEW public.view_occurences_manual_annotation;

CREATE MATERIALIZED VIEW public.view_occurences_manual_annotation
TABLESPACE pg_default
AS
 SELECT row_number() OVER () AS line_number,
    photos.photo_id AS id,
    concat((((photos.session_id)::text || '_'::text) || (photos."FileName")::text)) AS file_name,
    concat((((photos.relative_path)::text || '/'::text) || (photos."FileName")::text)) AS relative_path,
    label.tag_label AS species_name,
    photos."DateTimeOriginal" AS "time",
    photos."GPSDateTime" AS gps_time,
    photos."GPSLatitude" AS "decimalLatitude",
    photos."GPSLongitude" AS "decimalLongitude",
    photos.geometry_postgis,
    photos."LightValue",
    photos."Make",
    photos."Model",
    photos."ThumbnailImage"
   FROM photos_exif_core_metadata photos,
    annotation,
    label
  WHERE ((photos.photo_id = annotation.photo_id) AND (label.tag_id = annotation.tag_id))
  ORDER BY photos.session_id, photos.photo_id
WITH DATA;

ALTER TABLE public.view_occurences_manual_annotation
    OWNER TO "Reef_admin";


CREATE INDEX view_occurences_manual_annotation_geom_idx
    ON public.view_occurences_manual_annotation USING gist
    (geometry_postgis)
    TABLESPACE pg_default;
