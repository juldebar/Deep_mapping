DROP MATERIALIZED VIEW public.species_within_buffer;


CREATE MATERIALIZED VIEW public.species_within_buffer
TABLESPACE pg_default
AS
	SELECT 	
			row_number() OVER () AS ogc_fid,
			pictures.photo_id,
			pictures.session_id,
			pictures.photo_path,			
			pictures.photo_name,			
			pictures."FileName",						
			pictures.geometry_postgis AS geom,
			annotation.photo_id AS map_photo_id
			
		FROM 

		(
		SELECT 
		photos.photo_id,
		photos."FileName",	
		photos.session_id,	
		CONCAT(photos.relative_path||'/'||photos."FileName") AS photo_path,
		CONCAT(photos.session_id||'_'||photos."FileName") AS photo_name,
		photos.geometry_postgis 
		
		
		FROM  public."photos_exif_core_metadata" AS photos, aaa AS buffer  
		
		WHERE 
			st_within(photos.geometry_postgis,buffer.the_geom) 
			AND  
			buffer.ogc_fid=15
		) 
		AS pictures 
		
	LEFT JOIN annotation on annotation.photo_id=pictures.photo_id  
	
	
	
WITH DATA;

ALTER TABLE public.species_within_buffer OWNER TO "Reef_admin" ; 
    
CREATE UNIQUE INDEX ogc_fid_species_within_buffer_index ON species_within_buffer (ogc_fid) ;
	
--	CONCAT(photos.session_id||'_'||photos."FileName") IN(list_photo_identifier)
	

-- LEFT JOIN 

select count(*) from public.species_within_buffer
25717-25816

 row_number() OVER () AS ogc_fid,
    view_occurences_manual_annotation.species_name,
    count(view_occurences_manual_annotation.id) AS count,
    st_union(st_buffer(view_occurences_manual_annotation.geometry_postgis, (0.0003)::double precision)) AS the_geom 
    
   FROM view_occurences_manual_annotation 
   
  GROUP BY view_occurences_manual_annotation.species_name 
  

