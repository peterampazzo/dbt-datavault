SELECT hk_order_line_l, COUNT(*)
FROM {{ ref('order_line_l') }}
GROUP BY 1
HAVING COUNT(*) > 1
