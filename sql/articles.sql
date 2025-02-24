
WITH potential_duplicates AS (
    SELECT DISTINCT
/*        p1.id AS id1,
        p2.id AS id2,
        pv1.issn AS issn1,
        pv2.issn AS issn2,
        pv1.eissn AS eissn1,
        pv2.eissn AS eissn2,
        pv1.title AS title1,
        pv2.title AS title2,
        pv1.sourcetitle AS sourcetitle,
        pv2.sourcetitle AS sourcetitle2,
        pv1.pubyear,
        pv2.pubyear,
        pv1.publication_type_id,
        pv2.publication_type_id,
        pt1.label_sv AS publication_type_label1,
        pt2.label_sv AS publication_type_label2,
        LEFT(REGEXP_REPLACE(pv1.issn, '[^0-9Xx]', '', 'g'), 8) AS issn_cleaned1, 
        LEFT(REGEXP_REPLACE(pv2.issn, '[^0-9Xx]', '', 'g'), 8) AS issn_cleaned2 */
        p1.id AS id1, 
        p2.id AS id2,
        TRIM(BOTH FROM REGEXP_REPLACE(pv1.title, '[;\s\n]+$', '')) AS title1,
        TRIM(BOTH FROM REGEXP_REPLACE(pv2.title, '[;\s\n]+$', '')) AS title2,
        TRIM(BOTH FROM pv1.issn) AS issn1, 
        TRIM(BOTH FROM pv2.issn) AS issn2, 
        TRIM(BOTH FROM pv1.eissn) AS eissn1, 
        TRIM(BOTH FROM pv2.eissn) AS eissn2, 
        TRIM(BOTH FROM pv1.sourcevolume) AS sourcevolume1, 
        TRIM(BOTH FROM pv2.sourcevolume) AS sourcevolume2, 
        TRIM(BOTH FROM pv1.sourcepages) AS sourcepages1, 
        TRIM(BOTH FROM pv2.sourcepages) AS sourcepages2, 

        TRIM(BOTH FROM pi1.identifier_code) AS identifier_code1, 
        TRIM(BOTH FROM pi2.identifier_code) AS identifier_code2, 
        TRIM(BOTH FROM pi1.identifier_value) AS identifier_value1, 
        TRIM(BOTH FROM pi2.identifier_value) AS identifier_value2,

        pv1.pubyear

    FROM
        publication_versions pv1
    JOIN
        publication_versions pv2 ON pv1.id < pv2.id
/*        AND pv1.pubyear = pv2.pubyear
        AND pv1.publication_type_id = pv2.publication_type_id
        AND levenshtein(substring(pv1.sourcevolume FROM 1 FOR 20), substring(pv2.sourcevolume FROM 1 FOR 20)) < 10  -- Similar source volume
        AND levenshtein(substring(pv1.sourcepages FROM 1 FOR 20), substring(pv2.sourcepages FROM 1 FOR 20)) < 10  -- Similar source pages
        AND levenshtein(substring(pv1.title FROM 1 FOR 100), substring(pv2.title FROM 1 FOR 100)) < 10  -- Fuzzy title match */
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
        publication_identifiers pi2 ON pi2.publication_version_id = pv2.id AND pi1.identifier_code = pi2.identifier_code AND pi1.identifier_value = pi2.identifier_value AND pv1.id < pv2.id
    WHERE
        (
            (LEFT(REGEXP_REPLACE(pv1.issn,  '[^0-9Xx]', '', 'g'), 8) = LEFT(REGEXP_REPLACE(pv2.issn,  '[^0-9Xx]', '', 'g'), 8)) OR
            (LEFT(REGEXP_REPLACE(pv1.eissn, '[^0-9Xx]', '', 'g'), 8) = LEFT(REGEXP_REPLACE(pv2.eissn, '[^0-9Xx]', '', 'g'), 8))
        )
--        AND pv1.sourcevolume = pv2.sourcevolume
--        AND pv1.sourcepages = pv2.sourcepages
        AND levenshtein(substring(pv1.sourcevolume FROM 1 FOR 100), substring(pv2.sourcevolume FROM 1 FOR 100)) < 100  -- Fuzzy sourcevolume match
        AND levenshtein(substring(pv1.sourcepages FROM 1 FOR 100), substring(pv2.sourcepages FROM 1 FOR 100)) < 100  -- Fuzzy sourcepages match
/*        AND pv1.pubyear BETWEEN EXTRACT(YEAR FROM (DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '7 years')) AND EXTRACT(YEAR FROM (DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'))
        AND pv1.publication_type_id IN (16, 2, 1, 41, 42, 7, 44, 5, 3, 45, 22)*/
/*        AND levenshtein(substring(pv1.title FROM 1 FOR 100), substring(pv2.title FROM 1 FOR 100)) < 10  -- Fuzzy title match
        AND levenshtein(substring(pv1.sourcetitle FROM 1 FOR 20), substring(pv2.sourcetitle FROM 1 FOR 20)) < 10  -- Similar source volume  */
        AND ( 
            pv1.publication_type_id IN (5, 22, 7, 40, 18, 42)
            OR pv2.publication_type_id IN (5, 22, 7, 40, 18, 42)
        )
)
SELECT *
FROM potential_duplicates;


-- om issn, eissn, sourcevolume och sourcepages är samma

/*
SELECT 
        p1.id AS id1,
        p2.id AS id2,
        pv1.title AS title1,
        pv2.title AS title2,
        pv1.issn AS issn1,
        pv2.issn AS issn2,
        pv1.sourcevolume AS sourcevolume1,
        pv2.sourcevolume AS sourcevolume2,
        pv1.sourcepages AS sourcepages1,
        pv2.sourcepages AS sourcepages2,
        pv1.pubyear,
        pv2.pubyear,
        pv1.publication_type_id,
        pv2.publication_type_id,
        pt1.label_sv AS publication_type_label1,
        pt2.label_sv AS publication_type_label2,
        REGEXP_REPLACE(pv1.issn, '[^0-9Xx]', '', 'g') AS issn_cleaned1, 
        REGEXP_REPLACE(pv2.issn, '[^0-9Xx]', '', 'g') AS issn_cleaned2
FROM publications p1
JOIN publication_versions pv1 ON p1.current_version_id = pv1.id
JOIN publications p2 ON p1.id < p2.id
JOIN publication_versions pv2 ON p2.current_version_id = pv2.id
JOIN publication_types pt1 ON pv1.publication_type_id = pt1.id
JOIN publication_types pt2 ON pv2.publication_type_id = pt2.id
WHERE
    REGEXP_REPLACE(pv1.issn, '[^0-9Xx]', '', 'g') = REGEXP_REPLACE(pv2.issn, '[^0-9Xx]', '', 'g')  -- Cleaned ISSN match
    AND pv1.pubyear BETWEEN EXTRACT(YEAR FROM (DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '7 years')) AND EXTRACT(YEAR FROM (DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'))
    AND pv1.publication_type_id IN (16, 2, 1, 41, 42, 7, 44, 5, 3, 45, 22)
;



*/



