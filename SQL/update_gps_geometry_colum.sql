UPDATE public."photos_exif_core_metadata" SET geometry_postgis =
    (SELECT the_geom FROM public."session_2018_01_14_kite_Le_Morne" AS inferred WHERE inferred.photo_id=photos_exif_core_metadata.photo_id)  WHERE  "photos_exif_core_metadata".session_id='session_2018_01_14_kite_Le_Morne';    


--UPDATE accounts SET (contact_last_name, contact_first_name) =     (SELECT last_name, first_name FROM salesmen  WHERE salesmen.id = accounts.sales_id);
