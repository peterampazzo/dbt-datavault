{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
tracked_hashkey: hk_customer_h
source_models:
    - name: stg_customer
      rsrc_static: 'seed/customer'
    - name: stg_orders
      hk_column: hk_customer_h
      rsrc_static: 'seed/orders'
{%- endset -%}

{{ datavault4dbt.rec_track_sat(yaml_metadata=yaml_metadata) }}
