SELECT 
	photos_exif_core_metadata.photo_id AS photo_id, 
	CONCAT(photos_exif_core_metadata.session_id||'_'||photos_exif_core_metadata."FileName") AS photo_identifier, 		
	photos_exif_core_metadata.session_id, 
	photos_exif_core_metadata.session_photo_number, 
	CONCAT(photos_exif_core_metadata."relative_path"||'/'||photos_exif_core_metadata."FileName") AS photo_relative_file_path, 
	photos_in_segments.list_photos AS photos_in_this_segment, 
	photos_in_segments.list_time_photos, 
	photos_in_segments.count_photos, 
	unnest(array_positions(photos_in_segments.list_photos, photos_exif_core_metadata."FileName")) AS cell_number, 	
	(unnest(array_positions(photos_in_segments.list_photos, photos_exif_core_metadata."FileName"))::numeric / (count_photos+1)::numeric) AS ratio, 
	photos_in_segments.segment_wkt,
	photos_in_segments.segment_geom,
	ST_AsEWKT(ST_LineInterpolatePoint(segment_wkt, ((unnest(array_positions(list_photos, photos_exif_core_metadata."FileName"))::numeric / (count_photos+1)::numeric)))) AS "footprintWKT", 
	ST_X(ST_LineInterpolatePoint(segment_wkt, ((unnest(array_positions(list_photos, photos_exif_core_metadata."FileName"))::numeric / (count_photos+1)::numeric)))) AS "decimalLongitude",
	ST_Y(ST_LineInterpolatePoint(segment_wkt, ((unnest(array_positions(list_photos, photos_exif_core_metadata."FileName"))::numeric / (count_photos+1)::numeric)))) AS "decimalLatitude",
	ST_LineInterpolatePoint(segment_wkt, ((unnest(array_positions(list_photos, photos_exif_core_metadata."FileName"))::numeric / (count_photos+1)::numeric))) AS the_geom,
	photos_exif_core_metadata."GPSDateTime",
	photos_exif_core_metadata."DateTimeOriginal",
	photos_exif_core_metadata."LightValue",
	photos_exif_core_metadata."ImageSize",
	photos_exif_core_metadata."Make",
	photos_exif_core_metadata."Model",
	photos_exif_core_metadata."ThumbnailImage",
	photos_exif_core_metadata."PreviewImage",
	photos_exif_core_metadata."URL_original_image"

FROM 
	photos_exif_core_metadata, 
	(
	SELECT 
		row_number() OVER() AS segment_number,
		"session_id", 		
		GPS1_fid,
		array_agg("FileName") AS list_photos, 
		array_agg("DateTimeOriginal") AS list_time_photos, 
		array_length(array_agg("FileName"),1) AS count_photos,
		ST_AsEWKT(segment_geom) as segment_wkt,		
		segment_geom 
		FROM 
			(
			SELECT 
				row_number() OVER() AS photo_number, 				
				photos."session_id", 
				photos."relative_path", 				
				photos."FileName", 				
				photos."DateTimeOriginal", 
				GPS1.ogc_fid AS GPS1_fid, 
				GPS1."time" AS time_first_gps_point, 				
				GPS2.ogc_fid AS GPS2_fid, 				
				GPS2."time" AS time_second_gps_point, 
				(GPS2."time"-GPS1."time") AS diff, 
				ST_MakeLine(GPS1.the_geom,GPS2.the_geom) segment_geom  				
			FROM 
				gps_tracks as GPS1, 
				gps_tracks as GPS2, 
				photos_exif_core_metadata AS photos 
			WHERE  
				GPS2.ogc_fid = GPS1.ogc_fid +1
				AND GPS1.session_id=GPS2.session_id 
				AND GPS1.session_id=photos.session_id 
				AND GPS1.session_id=photos.session_id 				
				AND photos.session_id='session_2019_02_16_kite_Le_Morne_la_Pointe' 
				AND (photos."DateTimeOriginal"  - interval '778 second') < GPS2."time" 
				AND (photos."DateTimeOriginal"  - interval '778 second') >= GPS1."time" 

			ORDER BY GPS1.session_id, GPS1.ogc_fid ASC
			) AS foo
		GROUP BY session_id, GPS1_fid, segment_geom
		ORDER BY segment_number 
	) AS photos_in_segments 

WHERE 
	list_photos @> ARRAY[photos_exif_core_metadata."FileName"] 
	AND photos_exif_core_metadata.session_id=photos_in_segments.session_id 
	AND photos_exif_core_metadata.session_id='session_2019_02_16_kite_Le_Morne_la_Pointe'

ORDER BY photo_identifier
