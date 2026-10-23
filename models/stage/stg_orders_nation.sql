{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 'src_orders'
ldts: 'ldts'
rsrc: 'rsrc'
prejoined_columns:
    c_nationkey:
        ref_model: 'src_customer_latest'
        bk: 'c_nationkey'
        this_column_name: 'o_custkey'
        ref_column_name: 'c_custkey'
hashed_columns:
    hk_customer_h:
        - o_custkey
    hk_nation_h:
        - c_nationkey
    hk_customer_nation_l:
        - o_custkey
        - c_nationkey
{%- endset -%}

{{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}
