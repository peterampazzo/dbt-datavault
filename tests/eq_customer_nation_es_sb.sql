SELECT *
FROM (SELECT (SELECT COUNT(*) FROM {{ ref('customer_nation_es_sb') }}) AS a,
             (SELECT COUNT(*) FROM {{ ref('customer_nation_es') }}) AS b)
WHERE a != b
