{% set expected = 10 if var('load_until', '2024-01-02 00:00:00') == '2024-01-01 00:00:00' else 14 %}
SELECT *
FROM (SELECT COUNT(*) AS cnt FROM {{ ref('order_line_s') }})
WHERE cnt != {{ expected }}
