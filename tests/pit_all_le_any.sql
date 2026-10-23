SELECT *
FROM (SELECT (SELECT COUNT(*) FROM {{ ref('customer_pit_all') }}) AS all_cnt,
             (SELECT COUNT(*) FROM {{ ref('customer_pit_any') }}) AS any_cnt)
WHERE all_cnt > any_cnt
