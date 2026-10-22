SELECT cur_code, ldts, COUNT(*)
FROM {{ ref('currency_rs') }}
GROUP BY 1, 2
HAVING COUNT(*) > 1
