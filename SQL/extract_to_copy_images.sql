SELECT 
CONCAT(relative_path||'/'||"FileName") AS photo_identifier,
CONCAT(session_id||'_'||"FileName") AS photo_identifier 
FROM public.photos_exif_core_metadata 
ORDER BY session_id ASC 
LIMIT 100 


-- "session_2017_11_04_kite_Le_Morne"	"/session_2017_11_04_kite_Le_Morne/DCIM/108GOPRO"	"G0199034.JPG"	"session_2017_11_04_kite_Le_Morne_G0199034.JPG"
"/session_2017_11_04_kite_Le_Morne/DCIM/101GOPRO/G0192780.JPG"	"session_2017_11_04_kite_Le_Morne_G0192780.JPG"
