{{ config(materialized='view') }}

{%- set yaml_metadata -%}
ref_hub: 'currency_rh'
ref_satellites:
    currency_rs_v1:
        include:
            - cur_name
            - decimals
historized: 'full'
{%- endset -%}

{{ datavault4dbt.ref_table(yaml_metadata=yaml_metadata) }}
