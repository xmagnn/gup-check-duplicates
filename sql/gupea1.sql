SELECT pi.identifier_value
FROM publications p
JOIN publication_versions pv ON pv.id=p.current_version_id
JOIN publication_identifiers pi ON pi.publication_version_id=pv.id
WHERE pi.identifier_code = 'handle'
AND p.deleted_at IS NULL
AND (p.process_state NOT IN ('DRAFT', 'PREDRAFT') OR p.process_state IS NULL)
;
