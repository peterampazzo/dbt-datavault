SELECT hk_customer_nation_l, ldts, COUNT(*)
FROM {{ ref('customer_nation_es_sb') }}
GROUP BY 1, 2
HAVING COUNT(*) > 1
