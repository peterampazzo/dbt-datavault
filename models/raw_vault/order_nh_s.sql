{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
parent_hashkey: 'hk_order_nh_l'
src_payload:
    - o_orderstatus
    - o_orderpriority
    - o_clerk
    - o_comment
source_model: 'stg_orders'
{%- endset -%}

{{ datavault4dbt.nh_sat(yaml_metadata=yaml_metadata) }}
