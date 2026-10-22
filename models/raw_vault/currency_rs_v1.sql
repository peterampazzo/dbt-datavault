{{ config(materialized='view') }}

{%- set yaml_metadata -%}
ref_sat_v0: currency_rs
ref_keys: cur_code
hashdiff: hd_currency_rs
add_is_current_flag: true
{%- endset -%}

{{ datavault4dbt.ref_sat_v1(yaml_metadata=yaml_metadata) }}
