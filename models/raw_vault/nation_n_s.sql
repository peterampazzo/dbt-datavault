{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
parent_hashkey: 'hk_nation_h'
src_hashdiff: 'hd_nation_s'
src_payload:
    - n_name
    - n_comment
additional_columns:
    - n_regionkey
source_model: 'stg_nation'
{%- endset -%}

{{ datavault4dbt.sat_v0(yaml_metadata=yaml_metadata) }}
