{% set expected = 6 if var('load_until', '2024-01-02 00:00:00') == '2024-01-01 00:00:00' else 8 %}
SELECT *
FROM (SELECT COUNT(*) AS cnt FROM {{ ref('currency_rs') }})
WHERE cnt != {{ expected }}
