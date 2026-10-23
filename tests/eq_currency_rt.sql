SELECT *
FROM (SELECT (SELECT COUNT(*) FROM {{ ref('currency_rt') }}) AS a,
             (SELECT COUNT(*) FROM {{ ref('currency_rh') }}) AS b)
WHERE a != b
