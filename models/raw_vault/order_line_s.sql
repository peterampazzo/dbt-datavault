{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
parent_hashkey: 'hk_order_line_l'
src_hashdiff: 'hd_order_line_s'
src_payload:
    - l_partkey
    - l_quantity
    - l_extendedprice
source_model: 'stg_lineitem'
{%- endset -%}

{{ datavault4dbt.sat_v0(yaml_metadata=yaml_metadata) }}
