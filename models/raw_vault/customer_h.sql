{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
hashkey: 'hk_customer_h'
business_keys:
    - c_custkey
source_models:
    - name: stg_customer
      rsrc_static: 'seed/customer'
    - name: stg_orders
      bk_columns:
        - o_custkey
      rsrc_static: 'seed/orders'
    {%- if var('scn_hub_third_source', false) %}
    - name: stg_customer_phone
      bk_columns:
        - c_custkey
      rsrc_static: 'seed/phone'
    {%- endif %}
{%- if var('scn_disable_hwm', false) %}
disable_hwm: true
{%- endif %}
{%- endset -%}

{{ datavault4dbt.hub(yaml_metadata=yaml_metadata) }}
