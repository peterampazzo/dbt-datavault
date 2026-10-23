{{ config(materialized='view') }}

SELECT cur_code, cur_name, decimals, ldts
FROM {{ ref('ref_currency') }}
WHERE ldts <= TIMESTAMP '{{ var("load_until", "2024-01-02 00:00:00") }}'
