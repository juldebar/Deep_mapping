SELECT
	photos.photo_id,
	photos.session_id,	
	photos."FileName",
	CONCAT(photos.relative_path||'/'||photos."FileName") AS photo_path,
	CONCAT(photos.session_id||'_'||photos."FileName") AS photo_name,
	annotation.photo_id AS map_photo_id

FROM  public."photos_exif_core_metadata" AS photos LEFT JOIN annotation on annotation.photo_id=photos.photo_id 

WHERE st_within(geometry_postgis,ST_GeomFromText('polygon_wkt', 4326))
