{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
link_hashkey: 'hk_order_nh_l'
foreign_hashkeys:
    - 'hk_order_h'
payload:
    - o_orderdate
    - o_totalprice
    - o_shippriority
source_models: stg_orders
{%- endset -%}

{{ datavault4dbt.nh_link(yaml_metadata=yaml_metadata) }}
