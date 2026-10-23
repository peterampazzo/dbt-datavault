{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
link_hashkey: 'hk_customer_nation_l'
foreign_hashkeys:
    - 'hk_customer_h'
    - 'hk_nation_h'
source_models:
    - name: stg_customer
      rsrc_static: 'seed/customer'
    - name: stg_orders_nation
      rsrc_static: 'seed/orders'
{%- endset -%}

{{ datavault4dbt.link(yaml_metadata=yaml_metadata) }}
