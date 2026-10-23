{{ config(materialized='view') }}

SELECT c_custkey, c_name, c_address, c_nationkey, c_phone, c_acctbal, c_mktsegment, c_comment, ldts, rsrc
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY c_custkey ORDER BY ldts DESC) AS rn
    FROM {{ ref('src_customer') }}
)
WHERE rn = 1
