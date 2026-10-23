{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 'src_nation'
ldts: 'ldts'
rsrc: 'rsrc'
hashed_columns:
    hk_nation_h:
        - n_nationkey
    hd_nation_s:
        is_hashdiff: true
        use_rtrim: true
        columns:
            - n_name
            - n_comment
{%- endset -%}

{{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}
