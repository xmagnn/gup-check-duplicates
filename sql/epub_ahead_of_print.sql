SELECT p.id, pv.pubyear
FROM publications p
JOIN publication_versions pv ON pv.id=p.current_version_id
WHERE p.deleted_at IS NULL
AND (p.process_state NOT IN ('DRAFT', 'PREDRAFT') OR p.process_state IS NULL)
AND p.epub_ahead_of_print IS NOT NULL
;
