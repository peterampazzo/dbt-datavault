{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 'src_lineitem'
ldts: 'ldts'
rsrc: 'rsrc'
hashed_columns:
    hk_order_line_l:
        - l_orderkey
        - l_linenumber
    hk_order_h:
        - l_orderkey
    hd_order_line_s:
        is_hashdiff: true
        use_trim: false
        columns:
            - l_partkey
            - l_quantity
            - l_extendedprice
{%- endset -%}

{{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}
