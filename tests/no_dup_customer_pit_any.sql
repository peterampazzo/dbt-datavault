SELECT hk_customer_d, sdts, COUNT(*)
FROM {{ ref('customer_pit_any') }}
GROUP BY 1, 2
HAVING COUNT(*) > 1
