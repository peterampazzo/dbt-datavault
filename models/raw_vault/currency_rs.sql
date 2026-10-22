{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
source_model: stg_ref_currency
parent_ref_keys: cur_code
src_hashdiff: hd_currency_rs
src_payload:
    - cur_name
    - decimals
{%- endset -%}

{{ datavault4dbt.ref_sat_v0(yaml_metadata=yaml_metadata) }}
