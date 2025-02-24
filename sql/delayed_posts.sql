
-- Fördröjda poster: Poster som är fördröjda men inte epub ahead of print. Årtal ska vara med. GUP-id. 



SELECT p.id, pv.pubyear, ppd.postponed_until
FROM publications p
JOIN publication_versions pv ON pv.id=p.current_version_id
JOIN postpone_dates ppd ON ppd.publication_id=p.id
WHERE p.deleted_at IS NULL
AND (p.process_state NOT IN ('DRAFT', 'PREDRAFT') OR p.process_state IS NULL)
AND ppd.postponed_until > current_date
AND p.epub_ahead_of_print IS NULL
ORDER BY p.id;
;
