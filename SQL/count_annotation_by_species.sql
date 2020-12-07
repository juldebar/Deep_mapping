SELECT 
	species_name, 
	COUNT(id) as number_annotated_photos

FROM public.view_occurences_manual_annotation
GROUP BY species_name 
ORDER BY number_annotated_photos DESC -- LIMIT 10
