{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 'src_customer'
ldts: 'ldts'
rsrc: 'rsrc'
include_source_columns: false
enable_ghost_records: false
hashed_columns:
    hk_customer_h:
        - c_custkey
derived_columns:
    load_source:
        value: '!slim'
        datatype: 'STRING'
{%- endset -%}

{{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}
