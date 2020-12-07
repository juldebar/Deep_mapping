SELECT
	count(photos.photo_id),
	photos.session_id AS name_session

FROM  public."photos_exif_core_metadata" AS photos, annotation, label

WHERE photos.photo_id = annotation.photo_id AND annotation.tag_id=label.tag_id

GROUP BY name_session 

ORDER BY name_session ASC




