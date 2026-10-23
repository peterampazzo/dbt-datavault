{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
link_hashkey: 'hk_order_nh_l'
foreign_hashkeys:
    - 'hk_order_h'
payload:
    - o_orderdate
    - o_totalprice
    - o_shippriority
union_strategy: 'DISTINCT'
source_models:
    - name: stg_orders
      rsrc_static: 'seed/orders'
    - name: stg_orders_feed2
      rsrc_static: 'seed/orders2'
{%- endset -%}

{{ datavault4dbt.nh_link(yaml_metadata=yaml_metadata) }}
