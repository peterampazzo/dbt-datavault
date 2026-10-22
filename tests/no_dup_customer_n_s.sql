SELECT hk_customer_h, ldts, COUNT(*)
FROM {{ ref('customer_n_s') }}
GROUP BY 1, 2
HAVING COUNT(*) > 1
