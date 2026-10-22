{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
hashkey: 'hk_nation_h'
business_keys:
    - n_nationkey
source_models: stg_nation
{%- endset -%}

{{ datavault4dbt.hub(yaml_metadata=yaml_metadata) }}
