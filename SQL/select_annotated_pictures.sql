SELECT
	photos.relative_path AS relative_path,
	label.tag_label AS tag,
	photos.session_id AS name_session,	
	photos."FileName" AS file_name,		
	CONCAT(photos.session_id||'_'||photos."FileName") AS photo_name 	

FROM  public."photos_exif_core_metadata" AS photos, annotation, label

WHERE photos.photo_id = annotation.photo_id AND annotation.tag_id=label.tag_id


