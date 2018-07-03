SELECT ST_AsEWKT(ST_Line_Interpolate_Point(the_line, 0.20)) FROM (SELECT ST_AsEWKT(ST_MakeLine(wkb_geometry)) AS the_line FROM track_points WHERE (time=('2018-03-31 13:17:09+02')::timestamp OR time=('2018-03-31 13:17:10+02')::timestamp) AND session_id='XXXXXX') AS foo;


