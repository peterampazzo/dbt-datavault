{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
parent_hashkey: 'hk_customer_h'
src_hashdiff: 'hd_customer_n_s'
src_payload:
    - c_address
    - c_phone
    - c_acctbal
    - c_mktsegment
    - c_comment
    - c_nationkey
source_model: 'stg_customer'
{%- endset -%}

{{ datavault4dbt.sat_v0(yaml_metadata=yaml_metadata) }}
