SELECT *
FROM (SELECT (SELECT COUNT(*) FROM {{ ref('customer_nation_l_ms') }}) AS a,
             (SELECT COUNT(*) FROM {{ ref('customer_nation_l') }}) AS b)
WHERE a != b
