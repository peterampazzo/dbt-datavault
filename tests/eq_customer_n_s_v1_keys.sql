SELECT *
FROM (SELECT (SELECT COUNT(*) FROM {{ ref('customer_n_s_v1_keys') }}) AS a,
             (SELECT COUNT(*) FROM {{ ref('customer_n_s') }}) AS b)
WHERE a != b
