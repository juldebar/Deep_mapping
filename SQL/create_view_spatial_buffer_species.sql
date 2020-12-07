DROP MATERIALIZED VIEW public.spatial_buffer_species;

CREATE MATERIALIZED VIEW public.spatial_buffer_species
TABLESPACE pg_default
AS
 SELECT row_number() OVER () AS ogc_fid,
    view_occurences_manual_annotation.species_name,
    count(view_occurences_manual_annotation.id) AS count,
    st_union(st_buffer(view_occurences_manual_annotation.geometry_postgis, (0.0003)::double precision)) AS the_geom
   FROM view_occurences_manual_annotation
  GROUP BY view_occurences_manual_annotation.species_name
WITH DATA;

ALTER TABLE public.spatial_buffer_species
    OWNER TO "Reef_admin";


CREATE UNIQUE INDEX ogc_fid_index
    ON public.spatial_buffer_species USING btree
    (ogc_fid)
    TABLESPACE pg_default;
