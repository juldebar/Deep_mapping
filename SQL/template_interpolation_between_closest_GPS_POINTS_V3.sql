SELECT 
	photos_exif_core_metadata.photo_id, 
	photos_exif_core_metadata.session_id, 
	photos_exif_core_metadata.session_photo_number, 
	CONCAT(photos_exif_core_metadata."relative_path"||'/'||photos_exif_core_metadata."FileName") AS photo_relative_file_path, 
	photos_in_segments.list_photos, 
	unnest(array_positions(list_photos, photos_exif_core_metadata."FileName")) AS cell_number, 
	photos_in_segments.list_time_photos, 
	photos_in_segments.count_photos, 
	(unnest(array_positions(list_photos, photos_exif_core_metadata."FileName"))::numeric / (count_photos+1)::numeric) AS ratio, 
	ST_AsEWKT(segments) as segments,
	ST_AsEWKT(ST_LineInterpolatePoint(segments, ((unnest(array_positions(list_photos, photos_exif_core_metadata."FileName"))::numeric / (count_photos+1)::numeric)))), 
	ST_X(ST_LineInterpolatePoint(segments, ((unnest(array_positions(list_photos, photos_exif_core_metadata."FileName"))::numeric / (count_photos+1)::numeric)))) as latitude,
	ST_Y(ST_LineInterpolatePoint(segments, ((unnest(array_positions(list_photos, photos_exif_core_metadata."FileName"))::numeric / (count_photos+1)::numeric)))) as longitude,
	ST_LineInterpolatePoint(segments, ((unnest(array_positions(list_photos, photos_exif_core_metadata."FileName"))::numeric / (count_photos+1)::numeric))) as the_geom,
	photos_exif_core_metadata."GPSDateTime",
	photos_exif_core_metadata."DateTimeOriginal",
	photos_exif_core_metadata."LightValue",
	photos_exif_core_metadata."ImageSize",
	photos_exif_core_metadata."Model",
	photos_exif_core_metadata."ThumbnailImage",
	photos_exif_core_metadata."PreviewImage"
FROM 
	photos_exif_core_metadata, 
	(
	SELECT 
		row_number() OVER() AS photo_id, 
		session_id,
		GPS1_fid as fid_gps,
		array_agg("FileName") AS list_photos, 
		array_agg("DateTimeOriginal") AS list_time_photos, 
		array_length(array_agg("FileName"),1) AS count_photos, 
		segments 
		FROM 
			(
			SELECT 
				GPS1.ogc_fid AS GPS1_fid, 
				GPS2.ogc_fid AS GPS2_fid, 
				photos."FileName", 
				photos."DateTimeOriginal", 
				GPS1.session_id, 
				GPS1."time" AS time_first_point, 
				GPS2."time" AS time_second_point, 
				(GPS2."time"-GPS1."time") AS diff, 
				ST_AsEWKT(ST_MakeLine(GPS1.the_geom,GPS2.the_geom)) segments  
			FROM 
				gps_tracks as GPS1, 
				gps_tracks as GPS2, 
				photos_exif_core_metadata AS photos 
			WHERE  
				GPS2.ogc_fid = GPS1.ogc_fid +1
				AND GPS1.session_id=GPS2.session_id 
				AND GPS1.session_id=photos.session_id 
				AND GPS1.session_id='session_2019_02_16_kite_Le_Morne_la_Pointe' 
				AND (photos."DateTimeOriginal"  + interval '13848 second') < GPS2."time" 
				AND (photos."DateTimeOriginal"  + interval '13848 second') >= GPS1."time" 

			ORDER BY GPS1.session_id, GPS1.ogc_fid ASC
			) AS foo
		GROUP BY session_id, GPS1_fid, segments
		ORDER BY photo_id
	) AS photos_in_segments

WHERE 
	list_photos @> ARRAY[photos_exif_core_metadata."FileName"] 
	AND photos_exif_core_metadata.session_id=photos_in_segments.session_id 
	AND photos_exif_core_metadata.session_id='session_2019_02_16_kite_Le_Morne_la_Pointe'

ORDER BY photos_exif_core_metadata."FileName"
