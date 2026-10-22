SELECT hk_order_nh_l, ldts, COUNT(*)
FROM {{ ref('order_nh_s') }}
GROUP BY 1, 2
HAVING COUNT(*) > 1
