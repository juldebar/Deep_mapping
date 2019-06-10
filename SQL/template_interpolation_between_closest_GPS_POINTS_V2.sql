SELECT 
	photos_exif_core_metadata.ogc_fid, 
	photos_exif_core_metadata.session_id, 
	photos_exif_core_metadata.session_photo_number, 
	CONCAT(photos_exif_core_metadata."relative_path"||'/'||photos_exif_core_metadata."FileName") AS photo_relative_file_path, 
	photos_in_segments.list_photos, 
	unnest(array_positions(list_photos, photos_exif_core_metadata."FileName")) AS cell_number, 
	photos_in_segments.list_time_photos, 
	photos_in_segments count_photos, 
	(unnest(array_positions(list_photos, photos_exif_core_metadata."FileName"))::numeric / (count_photos+1)::numeric) AS ratio, 
	ST_AsEWKT(ST_LineInterpolatePoint(segments, ((unnest(array_positions(list_photos, photos_exif_core_metadata."FileName"))::numeric / (count_photos+1)::numeric)))), 
	ST_AsEWKT(segments) as segments 
FROM 
	photos_exif_core_metadata, 
	(
	SELECT 
		row_number() OVER() AS ogc_fid, 
		session_id,
		GPS1_fid as fid_gps,
		array_agg("FileName") AS list_photos, 
		array_agg("DateTimeOriginal") AS list_time_photos, 
		array_length(array_agg("FileName"),1) AS count_photos, 
		segments 
		FROM 
			(
			SELECT 
				GPS1.fid AS GPS1_fid, 
				GPS2.fid AS GPS2_fid, 
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
				GPS2.fid = GPS1.fid +1
				AND GPS1.session_id=GPS2.session_id 
				AND GPS1.session_id=photos.session_id 
				AND GPS1.session_id='session_2018_08_25_Zanzibar_Snorkelling' 
				AND photos."DateTimeOriginal" < GPS2."time" 
				AND photos."DateTimeOriginal" >= GPS1."time" 

			ORDER BY GPS1.session_id, GPS1.fid ASC
			) AS foo
		GROUP BY session_id, GPS1_fid, segments
		ORDER BY ogc_fid
	) AS photos_in_segments

WHERE 
	list_photos @> ARRAY[photos_exif_core_metadata."FileName"] 
	AND photos_exif_core_metadata.session_id=photos_in_segments.session_id 
	AND photos_exif_core_metadata.session_id='session_2018_08_25_Zanzibar_Snorkelling'

ORDER BY photos_exif_core_metadata."FileName"


-- CHECK ST_LineInterpolatePoints AND ST_LineLocatePoint
-- ORDER BY count_photos DESC
--  AND GPS1."time" AT TIME ZONE 'UTC' = (GPS2."time" AT TIME ZONE 'UTC' - interval '1 second')
-- GROUP BY diff(ogc_fid) < 1

-- ET
-- Pour chaque segment créé:
-- 	- select toutes les photos dont la date est inférieure à celle du deuxième point du segment et supérieure à celle du premier point.




-- 250000 => ferry
-- 100000 => hotel
-- Resto / pot => 55
-- 100€ Pascaline (50+50 sylvain)
