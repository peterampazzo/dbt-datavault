SELECT hk_customer_h
FROM {{ ref('customer_h') }}
WHERE length(hk_customer_h) != {{ 32 if env_var('DV_HASH', 'MD5') == 'MD5' else 64 }}
