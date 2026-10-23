SELECT hk_order_line_l, ldts, COUNT(*)
FROM {{ ref('order_line_s') }}
GROUP BY 1, 2
HAVING COUNT(*) > 1
