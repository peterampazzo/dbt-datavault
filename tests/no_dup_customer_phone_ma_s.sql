SELECT hk_customer_h, phone_type, ldts, COUNT(*)
FROM {{ ref('customer_phone_ma_s') }}
GROUP BY 1, 2, 3
HAVING COUNT(*) > 1
