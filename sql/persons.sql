  SELECT pe.id, pe.last_name, pe.first_name, string_agg(distinct i.value::text, '; '), count(p.id) as number_of_publ
  FROM people pe
  LEFT OUTER JOIN identifiers i ON i.person_id=pe.id
  JOIN people2publications p2p ON p2p.person_id=pe.id
  JOIN publication_versions pv ON p2p.publication_version_id=pv.id
  JOIN publications p ON p.current_version_id=pv.id
  JOIN departments2people2publications d2p2p ON d2p2p.people2publication_id=p2p.id
  WHERE p.deleted_at IS NULL
  AND p.published_at IS NOT NULL
  AND pe.id IN (
    SELECT p2p.person_id 
    FROM people2publications p2p
    JOIN departments2people2publications d2p2p ON d2p2p.people2publication_id=p2p.id
    WHERE d2p2p.department_id != 666
    ORDER BY p2p.person_id
  )
  GROUP BY pe.id, pe.last_name, pe.first_name;
