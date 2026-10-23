SELECT sdts
FROM {{ ref('currency_rt_snap') }}
WHERE sdts NOT IN (
    SELECT sdts FROM {{ ref('control_snap_v1_bounded') }} WHERE is_active
)
