{{ config(materialized='view') }}

SELECT *
FROM {{ ref('ref_currency') }}
WHERE ldts <= TIMESTAMP '{{ var("load_until", "2024-01-02 00:00:00") }}'
