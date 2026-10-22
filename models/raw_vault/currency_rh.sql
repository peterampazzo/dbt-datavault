{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
source_models: stg_ref_currency
ref_keys: cur_code
{%- endset -%}

{{ datavault4dbt.ref_hub(yaml_metadata=yaml_metadata) }}
