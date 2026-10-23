{% if var('scn_late_customer', false) and var('scn_disable_hwm', false) %}
  {% set expected = 10 if var('load_until', '2024-01-02 00:00:00') == '2024-01-01 00:00:00' else 12 %}
{% else %}
  {% set expected = 10 if var('load_until', '2024-01-02 00:00:00') == '2024-01-01 00:00:00' else 11 %}
{% endif %}
SELECT *
FROM (SELECT COUNT(*) AS cnt FROM {{ ref('customer_h') }})
WHERE cnt != {{ expected }}
