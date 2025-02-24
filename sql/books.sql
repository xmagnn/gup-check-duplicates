
WITH potential_duplicates AS (
    SELECT DISTINCT
/*        p1.id AS id1,
        p2.id AS id2,
        pv1.title AS title1,
        pv2.title AS title2,
        pv1.isbn AS isbn1,
        pv2.isbn AS isbn2,
        pv1.sourcetitle AS sourcetitle1,
        pv2.sourcetitle AS sourcetitle2,
        pv1.sourcepages AS sourcepages1,
        pv2.sourcepages AS sourcepages2,
        pv1.pubyear,
        pv2.pubyear,
        pv1.publication_type_id,
        pv2.publication_type_id,
        pt1.label_sv AS publication_type_label1,
        pt2.label_sv AS publication_type_label2,
        LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 13) AS isbn_cleaned1, 
        LEFT(REGEXP_REPLACE(pv2.isbn, '[^0-9Xx]', '', 'g'), 13) AS isbn_cleaned2, 
        LEFT(LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 13), 3) AS LEFT13,
        LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'),  8) AS LEFT18,
        LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 13) AS LEFT113,
        CASE
          WHEN LEFT(LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 13), 3) IN ('978', '979') THEN LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 13) = LEFT(REGEXP_REPLACE(pv2.isbn, '[^0-9Xx]', '', 'g'), 13)
          ELSE LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'),  8) = LEFT(REGEXP_REPLACE(pv2.isbn, '[^0-9Xx]', '', 'g'),  8)
        END AS isbn_match */
        p1.id AS id1,
        p2.id AS id2,
        TRIM(BOTH FROM pv1.title) AS title1,
        TRIM(BOTH FROM pv2.title) AS title2,
        TRIM(BOTH FROM pv1.sourcetitle) AS sourcetitle1,
        TRIM(BOTH FROM pv2.sourcetitle) AS sourcetitle2,
        TRIM(BOTH FROM pv1.isbn) AS isbn1,
        TRIM(BOTH FROM pv2.isbn) AS isbn2, 
        pt1.label_sv AS pubtype1,
        pt2.label_sv AS pubtype2,
        pi1.identifier_code || pi1.identifier_value AS identifier1,
        pi2.identifier_code || pi2.identifier_value AS identifier2

    FROM
        publication_versions pv1
    JOIN
        publication_versions pv2 ON pv1.id < pv2.id
    JOIN
        publications p1 ON pv1.id = p1.current_version_id AND p1.deleted_at IS NULL AND p1.process_state NOT IN ('DRAFT', 'PREDRAFT') 
    JOIN
        publications p2 ON pv2.id = p2.current_version_id AND p2.deleted_at IS NULL AND p2.process_state NOT IN ('DRAFT', 'PREDRAFT') 
    JOIN 
        publication_types pt1 ON pv1.publication_type_id = pt1.id
    JOIN 
        publication_types pt2 ON pv2.publication_type_id = pt2.id
    JOIN
        publication_identifiers pi1 ON pi1.publication_version_id = pv1.id 
    JOIN 
        publication_identifiers pi2 ON pi2.publication_version_id = pv2.id
    WHERE
        
        -- Compare sanitized ISBNs
        (
            (LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 13) = LEFT(REGEXP_REPLACE(pv2.isbn, '[^0-9Xx]', '', 'g'), 13) AND 
             LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 3) IN ('978', '979'))
            OR
            LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 8) = LEFT(REGEXP_REPLACE(pv2.isbn, '[^0-9Xx]', '', 'g'), 8)
        )
        -- Compare source pages for specific publication type
        AND (pv1.publication_type_id != 10 OR levenshtein(SUBSTRING(pv1.sourcetitle FROM 1 FOR 255), SUBSTRING(pv2.sourcetitle FROM 1 FOR 255)) < 2)
        -- Compare titles for specific publication type
        AND (pv1.publication_type_id != 43 OR levenshtein(SUBSTRING(pv1.title FROM 1 FOR 255), SUBSTRING(pv2.title FROM 1 FOR 255)) < 3)
        -- Fuzzy matching on source titles
        AND levenshtein(SUBSTRING(pv1.sourcetitle FROM 1 FOR 255), SUBSTRING(pv2.sourcetitle FROM 1 FOR 255)) < 3
        -- Fuzzy matching on publication titles
        AND levenshtein(SUBSTRING(pv1.title FROM 1 FOR 255), SUBSTRING(pv2.title FROM 1 FOR 255)) < 10
      
        AND pi1.identifier_code = pi2.identifier_code AND pi1.identifier_value = pi2.identifier_value
        -- AND pv1.sourcetitle % pv2.sourcetitle AND pv1.title % pv2.title  
        AND (
             pv1.publication_type_id IN (30, 9, 10, 28, 17, 19, 8, 16, 41)  
          OR pv2.publication_type_id IN (30, 9, 10, 28, 17, 19, 8, 16, 41)
        )
        AND EXTRACT(YEAR FROM pv1.updated_at) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
        AND EXTRACT(YEAR FROM pv2.updated_at) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
--        AND pv1.pubyear = EXTRACT(YEAR FROM CURRENT_DATE) - 1
--        AND pv2.pubyear = EXTRACT(YEAR FROM CURRENT_DATE) - 1


)
    
   
    /*
    
    WHERE
  /*      CASE 
          WHEN LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 3) IN ('978', '979') THEN LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 13) = LEFT(REGEXP_REPLACE(pv2.isbn, '[^0-9Xx]', '', 'g'), 13)
          ELSE LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 8) = LEFT(REGEXP_REPLACE(pv2.isbn, '[^0-9Xx]', '', 'g'), 8)
        END*/
        CASE
          WHEN LEFT(LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 13), 3) IN ('978', '979') THEN LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 13) = LEFT(REGEXP_REPLACE(pv2.isbn, '[^0-9Xx]', '', 'g'), 13)
          ELSE LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'),  8) = LEFT(REGEXP_REPLACE(pv2.isbn, '[^0-9Xx]', '', 'g'),  8)
        END
--        (          -- Cleaned isbn match
--          LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'),  8) = LEFT(REGEXP_REPLACE(pv2.isbn, '[^0-9Xx]', '', 'g'),  8)  OR
--          LEFT(REGEXP_REPLACE(pv1.isbn, '[^0-9Xx]', '', 'g'), 13) = LEFT(REGEXP_REPLACE(pv2.isbn, '[^0-9Xx]', '', 'g'), 13)  
--        )
/*        AND pv1.pubyear BETWEEN EXTRACT(YEAR FROM (DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '7 years')) AND EXTRACT(YEAR FROM (DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'))
        AND pv1.publication_type_id IN (30, 28, 17, 18, 46, 8, 19, 10, 9)
        AND pv1.pubyear = pv2.pubyear
        AND pv1.publication_type_id = pv2.publication_type_id*/
--        AND levenshtein(substring(pv1.sourcevolume FROM 1 FOR 20), substring(pv2.sourcevolume FROM 1 FOR 20)) < 3  -- Similar source volume
--        AND levenshtein(substring(pv1.sourcepages FROM 1 FOR 20), substring(pv2.sourcepages FROM 1 FOR 20)) < 1  -- Similar source pages
 --       AND pv1.sourcepages = pv2.sourcepages
        AND levenshtein(substring(pv1.sourcetitle FROM 1 FOR 20), substring(pv2.sourcetitle FROM 1 FOR 20)) < 3  -- Similar source volume
        AND levenshtein(substring(pv1.title FROM 1 FOR 100), substring(pv2.title FROM 1 FOR 100)) < 10  -- Fuzzy title match
        CASE
          WHEN pv1.publication_type_id = 10 THEN levenshtein(pv1.sourcepages, pv2.sourcepages) < 2
          ELSE 0
        END
        CASE
          WHEN pv1.publication_type_id = 43 THEN levenshtein(pv1.title, pv2.title) < 3
          ELSE 0
        END
)   */
SELECT *
FROM potential_duplicates;

/*
JUSTERINGAR
- Om kapitel i bok (10) så måste sourcepages vara identiska (eller tomma) eller 1 
- Om Bidrag till encyklopedi (43) så måste titlarna vara ännu närmare varann eller typ 3
*/



/*
  SELECT p.id, pv.pubyear, pv.title, pt.label_sv
  FROM publications p
  JOIN publication_versions pv ON p.current_version_id = pv.id
  JOIN publication_types pt ON pt.id=pv.publication_type_id
  JOIN (
    SELECT substr(translate(lower(trim(pv1.title)), 'aeiouyåäöáàéèíìóòúùü;.:-_()[]/+´` ', 'x'),0,20) AS t_title,
    pv1.pubyear,
    substr(translate(lower(trim(pv1.isbn)), 'abcdefghijklmnopqrstuvwyzåäö()-.,: ', ' '),0,8) AS isbn,
    pv1.sourcevolume,
    substr(translate(lower(trim(pv1.sourcepages)), 'abcdefghijklmnopqrstuvwyzåäö()-.,: ', ' '),0,2) AS page, 
    pv1.publication_type_id,
    count(*) AS antal
    FROM publications p1
    JOIN publication_versions pv1 ON p1.current_version_id=pv1.id
    WHERE p1.deleted_at IS NULL
    AND pv1.isbn IS NOT NULL
    GROUP BY substr(translate(lower(trim(pv1.title)), 'aeiouyåäöáàéèíìóòúùü;.:-_()[]/+´` ', 'x'),0,20), pv1.pubyear, substr(translate(lower(trim(pv1.isbn)), 'abcdefghijklmnopqrstuvwyzåäö()-.,: ', ' '),0,8), pv1.sourcevolume, substr(translate(lower(trim(pv1.sourcepages)), 'abcdefghijklmnopqrstuvwyzåäö()-.,: ', ' '),0,2), pv1.publication_type_id
    ORDER BY antal desc, substr(translate(lower(trim(pv1.isbn)), 'abcdefghijklmnopqrstuvwyzåäö()-.,: ', ' '),0,8)
  ) AS c_tmp ON c_tmp.t_title=substr(translate(lower(trim(pv.title)),'aeiouyåäöáàéèíìóòúùü;.:-_()[]/+´` ', 'x'),0,20)
  WHERE p.deleted_at IS NULL
  AND p.published_at IS NOT NULL
  AND c_tmp.antal > 1
;
*/
