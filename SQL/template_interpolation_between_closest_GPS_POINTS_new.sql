
CREATE MATERIALIZED VIEW IF NOT EXISTS  "view_session_2018_03_24_kite_Le_Morne" AS 


		SELECT 
			      row_number() OVER (ORDER BY photos_exif_core_metadata."FileName") AS OID,
			      photos_exif_core_metadata.session_id,
			      photos_exif_core_metadata."FileName",
			      relative_path,
			      photos_exif_core_metadata."DateTimeOriginal",
			      (photos_exif_core_metadata."DateTimeOriginal" AT TIME ZONE 'UTC' - interval '42 second') AS estimated_time,


			      CASE
				WHEN (photos_exif_core_metadata."FileName" LIKE list_photos[1] AND photos_in_segment=1)  THEN ST_X(ST_LineInterpolatePoint(segment, 0.5))
				WHEN (photos_exif_core_metadata."FileName" LIKE list_photos[1] AND photos_in_segment=2)  THEN ST_X(ST_LineInterpolatePoint(segment, 0.16))
				WHEN photos_exif_core_metadata."FileName" LIKE list_photos[2] THEN ST_X(ST_AsEWKT(ST_LineInterpolatePoint(segment, 0.82)))
				ELSE 0
			      END AS  longitude,
			      CASE
				WHEN (photos_exif_core_metadata."FileName" LIKE list_photos[1] AND photos_in_segment=1)  THEN ST_Y(ST_LineInterpolatePoint(segment, 0.5))
				WHEN (photos_exif_core_metadata."FileName" LIKE list_photos[1] AND photos_in_segment=2)  THEN ST_Y(ST_LineInterpolatePoint(segment, 0.16))
				WHEN photos_exif_core_metadata."FileName" LIKE list_photos[2] THEN ST_Y(ST_AsEWKT(ST_LineInterpolatePoint(segment, 0.82)))
				ELSE 0
			      END AS  latitude,
			      CASE
				WHEN (photos_exif_core_metadata."FileName" LIKE list_photos[1] AND photos_in_segment=1)  THEN ST_AsEWKT(ST_LineInterpolatePoint(segment, 0.5))
				WHEN (photos_exif_core_metadata."FileName" LIKE list_photos[1] AND photos_in_segment=2)  THEN ST_AsEWKT(ST_LineInterpolatePoint(segment, 0.16))
				WHEN photos_exif_core_metadata."FileName" LIKE list_photos[2] THEN ST_AsEWKT(ST_LineInterpolatePoint(segment, 0.82))
				ELSE 'other'
			      END AS  inferred_geom,
			      CASE
				WHEN (photos_exif_core_metadata."FileName" LIKE list_photos[1] AND photos_in_segment=1)  THEN ST_LineInterpolatePoint(segment, 0.5)
				WHEN (photos_exif_core_metadata."FileName" LIKE list_photos[1] AND photos_in_segment=2)  THEN ST_LineInterpolatePoint(segment, 0.16)
				WHEN photos_exif_core_metadata."FileName" LIKE list_photos[2] THEN ST_LineInterpolatePoint(segment, 0.82)
				ELSE NULL
			      END AS  the_geom,
			      mean_altitude,
			      photos_exif_core_metadata."ThumbnailImage"



			FROM 
			    photos_exif_core_metadata, 
			    (SELECT session_id, array_agg("FileName") AS list_photos, array_length(array_agg("FileName"),1) AS photos_in_segment, list_gps_points, count_gps_points, (SELECT AVG(t) FROM UNNEST(list_altitude) AS t) AS mean_altitude, segment
				FROM 
				(
					SELECT 
					row_number() OVER(ORDER BY session_id) AS OID, 
					session_id,
					"FileName", 
					array_agg(GPS_trackpoint_id) AS list_gps_points, 
					array_agg(altitude) AS list_altitude, 
					array_length(array_agg(GPS_trackpoint_id),1) AS count_gps_points, 
					ST_AsEWKT(ST_MakeLine(the_geom)) AS segment 
					FROM 
						     (
						      SELECT photos.session_id AS session_id, gps_tracks.fid AS GPS_trackpoint_id, photos."FileName", gps_tracks."time" AS GPS_time, photos."DateTimeOriginal" AS photo_time, gps_tracks.the_geom, gps_tracks.altitude AS altitude
						      FROM photos_exif_core_metadata photos, gps_tracks 
						      WHERE  
							photos.session_id='session_2018_03_24_kite_Le_Morne' AND gps_tracks.session_id='session_2018_03_24_kite_Le_Morne'
							AND (gps_tracks."time" AT TIME ZONE 'UTC' = (photos."DateTimeOriginal" AT TIME ZONE 'UTC' - interval '42 second') OR  gps_tracks."time" AT TIME ZONE 'UTC' = (photos."DateTimeOriginal" AT TIME ZONE 'UTC' - interval '41 second'))
						      ORDER BY GPS_trackpoint_id
						      ) AS foo 
					WHERE session_id='session_2018_03_24_kite_Le_Morne' 
					GROUP BY session_id, "FileName"
					ORDER BY session_id, "FileName") AS the_query  
				GROUP BY session_id, list_gps_points, count_gps_points, segment, list_altitude
				ORDER BY session_id, list_gps_points
				) AS final_query
			WHERE 
				list_photos @> ARRAY[photos_exif_core_metadata."FileName"] 
			    AND photos_in_segment > 0 AND photos_in_segment < 3 
			    AND count_gps_points > 1 AND photos_exif_core_metadata.session_id='session_2018_03_24_kite_Le_Morne' AND final_query.session_id='session_2018_03_24_kite_Le_Morne' 

WITH DATA
