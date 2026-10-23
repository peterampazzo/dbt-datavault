{{ config(materialized='view') }}

SELECT
    {%- if var('scn_drop_source_col', false) %}
    c_custkey, c_name, c_address, c_nationkey, c_phone, c_acctbal, c_mktsegment, ldts, rsrc
    {%- else %}
    c_custkey, c_name, c_address, c_nationkey, c_phone, c_acctbal, c_mktsegment, c_comment, ldts, rsrc
    {%- endif %}
FROM {{ ref('customer') }}
WHERE ldts <= TIMESTAMP '{{ var("load_until", "2024-01-02 00:00:00") }}'
{%- if var('scn_late_customer', false) %}
UNION ALL
SELECT 10, 'judy', 'addr10', 2, '1010', CAST(1000.00 AS DECIMAL(12,2)), 'auto', 'comment j10', TIMESTAMP '2024-01-01 00:00:00', 'seed/customer'
{%- endif %}
