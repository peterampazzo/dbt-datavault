{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
link_hashkey: 'hk_order_line_l'
foreign_hashkeys:
    - 'hk_order_h'
    - 'l_linenumber'
additional_columns:
    - l_partkey
source_models: stg_lineitem
{%- endset -%}

{{ datavault4dbt.link(yaml_metadata=yaml_metadata) }}
