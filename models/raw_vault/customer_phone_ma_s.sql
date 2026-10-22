{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
source_model: 'stg_customer_phone'
parent_hashkey: 'hk_customer_h'
src_hashdiff: 'hd_customer_phone_ma_s'
src_ma_key: 'phone_type'
src_payload:
    - phone_number
{%- endset -%}

{{ datavault4dbt.ma_sat_v0(yaml_metadata=yaml_metadata) }}
