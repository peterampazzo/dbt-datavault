{{ config(materialized='view') }}

SELECT n_nationkey, n_name, n_regionkey, n_comment, ldts, rsrc
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY n_nationkey ORDER BY ldts DESC) AS rn
    FROM {{ ref('src_nation') }}
)
WHERE rn = 1
