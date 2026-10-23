{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 'src_ref_currency'
ldts: 'ldts'
rsrc: '!seed.currency'
hashed_columns:
    hd_currency_rs:
        is_hashdiff: true
        columns:
            - cur_name
            - decimals
{%- endset -%}

{{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}
