{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 'src_nation'
ldts: 'ldts'
rsrc: 'rsrc'
hashed_columns:
    hk_nation_h:
        - n_nationkey
{%- endset -%}

{{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}
