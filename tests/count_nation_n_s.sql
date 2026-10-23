{% set expected = 7 if var('load_until', '2024-01-02 00:00:00') == '2024-01-01 00:00:00' else 8 %}
SELECT *
FROM (SELECT COUNT(*) AS cnt FROM {{ ref('nation_n_s') }})
WHERE cnt != {{ expected }}
