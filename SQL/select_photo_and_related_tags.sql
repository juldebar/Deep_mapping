SELECT 
	photos.photo_id,
	annotation.tag_id
	

FROM  public."photos_exif_core_metadata" as photos, annotation 
where session_id='session_2018_05_06_kite_Le_Morne_Manawa' AND 
"FileName"='G0042575.JPG'
-- 196508


SELECT 
	annotation.photo_id,
	annotation.tag_id
	

FROM   annotation where photo_id=196508
