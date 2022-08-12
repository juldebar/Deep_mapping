SELECT
	photo_id,
	CONCAT(photos.session_id||'_'||photos."FileName") AS photo_name		

FROM  public."photos_exif_core_metadata" AS photos 

WHERE photos.session_id IN(list_sessions) AND CONCAT(photos.session_id||'_'||photos."FileName") IN(list_photo_identifier)


--UPDATE accounts SET (contact_last_name, contact_first_name) =     (SELECT last_name, first_name FROM salesmen  WHERE salesmen.id = accounts.sales_id);
