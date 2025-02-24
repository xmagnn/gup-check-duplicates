SELECT h.handle AS handle, mdv.text_value AS date
FROM handle h
JOIN item i ON i.uuid=h.resource_id
JOIN metadatavalue mdv ON mdv.dspace_object_id=i.uuid
JOIN metadatafieldregistry mrf ON mrf.metadata_field_id=mdv.metadata_field_id
WHERE mrf.qualifier = 'issued'
AND mdv.metadata_field_id = '15'
AND mdv.text_value LIKE (EXTRACT(YEAR FROM CURRENT_DATE) - 1 || '%')
AND h.resource_id IN (
	select i2.uuid
	FROM item i2
	WHERE uuid IN (
		SELECT dspace_object_id
		FROM metadatavalue 
		WHERE metadata_field_id=81 
		AND text_value LIKE 'Doctor%'
		ORDER BY dspace_object_id
	) 
	AND i2.withdrawn='f' AND i2.in_archive='t'
)
AND h.handle NOT in (
	SELECT handle FROM already_in_gup

)
;
