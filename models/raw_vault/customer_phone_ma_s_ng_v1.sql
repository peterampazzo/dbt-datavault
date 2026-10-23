{{ config(materialized='view') }}

{%- set yaml_metadata -%}
sat_v0: 'customer_phone_ma_s_ng'
hashkey: 'hk_customer_h'
hashdiff: 'hd_customer_phone_ma_s'
ma_attribute:
    - phone_type
ledts_alias: 'ledts'
add_is_current_flag: true
{%- endset -%}

{{ datavault4dbt.ma_sat_v1(yaml_metadata=yaml_metadata) }}
