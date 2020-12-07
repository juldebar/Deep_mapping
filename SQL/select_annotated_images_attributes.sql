
 SELECT 
    line_number,
    id,
    file_name,
    relative_path,
    species_name,
    gps_time,
    st_y(geometry_postgis) AS "decimalLatitude",
    st_x(geometry_postgis) AS "decimalLongitude",
    st_astext(geometry_postgis),
    "LightValue",
    "Make",
    "Model",
    CONCAT( 'http://162.38.140.205/tmp/Deep_mapping/'||file_name) AS "URL"
   FROM 
     public.view_occurences_manual_annotation 
     
--      LIMIT 100
  
