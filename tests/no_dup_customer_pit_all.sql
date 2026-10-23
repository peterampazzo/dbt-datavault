SELECT hk_customer_d, sdts, COUNT(*)
FROM {{ ref('customer_pit_all') }}
GROUP BY 1, 2
HAVING COUNT(*) > 1
