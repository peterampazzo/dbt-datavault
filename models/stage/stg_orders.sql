{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 'src_orders'
ldts: 'ldts'
rsrc: 'rsrc'
hashed_columns:
    hk_order_h:
        - o_orderkey
    hk_customer_h:
        - o_custkey
    hk_order_nh_l:
        - o_orderkey
    hd_order_nh_s:
        is_hashdiff: true
        columns:
            - o_orderstatus
            - o_orderpriority
            - o_clerk
            - o_comment
{%- endset -%}

{{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}
