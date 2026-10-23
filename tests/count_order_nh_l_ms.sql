{% set expected = 15 if var('load_until', '2024-01-02 00:00:00') == '2024-01-01 00:00:00' else 20 %}
SELECT *
FROM (SELECT COUNT(*) AS cnt FROM {{ ref('order_nh_l_ms') }})
WHERE cnt != {{ expected }}
