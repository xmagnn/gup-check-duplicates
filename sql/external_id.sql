/*
SELECT *
FROM (
  SELECT  pi.identifier_code, 
          pi.identifier_value, 
          count(p.id) AS numberOfPublications, 
          STRING_AGG(p.id::text, '; ') AS pubids, 
          STRING_AGG(pv.publication_type_id::text, '; ') AS pubtypes,
          STRING_AGG(pv.pubyear::text, '; ') AS pubyears
  FROM publications p
  JOIN publication_versions pv ON p.current_version_id=pv.id
  JOIN publication_identifiers pi ON pi.publication_version_id=pv.id
  WHERE p.deleted_at IS NULL
  AND p.published_at IS NOT NULL
  GROUP BY pi.identifier_code, pi.identifier_value
  ORDER BY numberOfPublications desc
  ) AS a 
WHERE a.numberOfPublications > 1
;
*/


-- Dubletter på externa IDn: Uppdelat efter publikationstyp. Kan man använda datumet då 
-- posten är skapad för att undvika att titta på samma potentiella dubletter igen?  

/*
SELECT 
    pi.identifier_code, 
    pi.identifier_value, 
    COUNT(p.id) AS numberOfPublications, 
    STRING_AGG(p.id::text, '; ') AS pubids, 
    STRING_AGG(pv.publication_type_id::text, '; ') AS pubtypes,
    STRING_AGG(pv.pubyear::text, '; ') AS pubyears
FROM publications p
JOIN publication_versions pv ON p.current_version_id = pv.id
JOIN publication_identifiers pi ON pi.publication_version_id = pv.id
WHERE p.deleted_at IS NULL
  AND p.published_at IS NOT NULL
GROUP BY pi.identifier_code, pi.identifier_value
HAVING COUNT(p.id) > 1
ORDER BY numberOfPublications DESC;
*/

/*
SELECT pi1.identifier_code || pi1.identifier_value
        
FROM publications p1
JOIN publications p2 ON p1.id < p2.id
JOIN publication_versions pv1 ON pv1.id=p1.current_version_id
JOIN publication_versions pv2 ON pv2.id=p1.current_version_id
--JOIN people2publications p2p ON p2p.publication_version_id=pv.id
--JOIN departments2people2publications d2p2p ON d2p2p.people2publication_id=p2p.id
--JOIN departments d ON d.id=d2p2p.department_id
--JOIN people pe ON pe.id=p2p.person_id
JOIN publication_identifiers pi1 ON pi1.publication_version_id=pv1.id
JOIN publication_identifiers pi2 ON pi2.publication_version_id=pv2.id
WHERE p1.deleted_at IS NULL
AND (p1.process_state NOT IN ('DRAFT', 'PREDRAFT') OR p1.process_state IS NULL)
AND pi1.identifier_code  = pi1.identifier_code 
AND pi1.identifier_value = pi1.identifier_value
*/



SELECT 
    pi.identifier_code,
    pi.identifier_value,
    COUNT(p.id) AS number_of_publications,
    STRING_AGG(p.id::text, ', ') AS publication_ids,
    STRING_AGG(DISTINCT pv.pubyear::text, ', ') AS publication_years, 
    STRING_AGG(DISTINCT pt.label_sv::text, ', ') AS publication_types

FROM publications p
JOIN publication_versions pv ON pv.id = p.current_version_id
JOIN publication_identifiers pi ON pi.publication_version_id = pv.id
JOIN publication_types pt ON pt.id = pv.publication_type_id
WHERE p.deleted_at IS NULL
  AND (p.process_state NOT IN ('DRAFT', 'PREDRAFT') OR p.process_state IS NULL)
  -- AND YEAR(pv.updated_at) = YEAR(CURDATE()) - 1
  AND EXTRACT(YEAR FROM pv.updated_at) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
GROUP BY pi.identifier_code, pi.identifier_value
HAVING COUNT(p.id) > 1
--ORDER BY pi.identifier_code, pi.identifier_value;
ORDER BY COUNT(p.id) DESC, pi.identifier_code, pi.identifier_value;



/*

/*
Artiklar
5, 22, 7, 40, 18, 42

Böcker, kapitel och rapporter
30, 9, 10, 28, 17, 19, 8, 16, 41

Konferensbidrag
2, 1, 3, 45

Konstnärliga arbeten
34

Övrigt
44, 46, 43, 13, 21
*/

  5 | Artikel i vetenskaplig tidskrift
 22 | Forskningsöversiktsartikel (Review article)
  7 | Artikel i övriga tidskrifter
 40 | Inledande text i tidskrift
 18 | Recension
 42 | Artikel i dagstidning

 30 | Lärobok
  9 | Bok
 10 | Kapitel i bok
 28 | Textkritisk utgåva
 17 | Doktorsavhandling
 19 | Licentiatsavhandling
  8 | Samlingsverk (red.)
 16 | Rapport
 41 | Kapitel i rapport

  2 | Paper i proceeding
  1 | Konferensbidrag (offentliggjort, men ej förlagsutgivet)
  3 | Poster (konferens)
 45 | Proceeding (red.)
 
 34 | Konstnärligt arbete
 
 44 | Special / temanummer av tidskrift (red.)
 46 | Working paper
 43 | Bidrag till encyklopedi
 13 | Patent
 21 | Annan publikation
 
 23 | Konstnärligt forsknings- och utvecklingsarbete
*/