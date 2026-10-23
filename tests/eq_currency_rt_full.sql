-- 'full' historization produces one row per (ref key, distinct satellite ldts);
-- every version's own ldts must therefore be present for its key.
SELECT s.cur_code, s.ldts
FROM {{ ref('currency_rs_v1') }} s
LEFT JOIN {{ ref('currency_rt_full') }} f
    ON f.cur_code = s.cur_code AND f.ldts = s.ldts
WHERE f.cur_code IS NULL
    AND s.rsrc NOT IN ('SYSTEM', 'ERROR')  -- ghost records are not historized
