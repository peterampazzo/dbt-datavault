{{ config(materialized='view') }}

{%- set yaml_metadata -%}
sat_v0: 'customer_n_s'
hashkey: 'hk_customer_h'
hashdiff: 'hd_customer_n_s'
ledts_alias: 'ledts'
add_is_current_flag: true
include_payload: false
{%- endset -%}

{{ datavault4dbt.sat_v1(yaml_metadata=yaml_metadata) }}
