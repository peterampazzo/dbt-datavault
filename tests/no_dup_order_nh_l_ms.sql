SELECT hk_order_nh_l, COUNT(*)
FROM {{ ref('order_nh_l_ms') }}
GROUP BY 1
HAVING COUNT(*) > 1
