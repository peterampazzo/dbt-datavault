{{ config(materialized='view') }}

{%- set yaml_metadata -%}
ref_hub: 'currency_rh'
ref_satellites:
    currency_rs_v1:
        include:
            - cur_name
            - decimals
historized: 'snapshot'
snapshot_relation: 'control_snap_v1_bounded'
snapshot_trigger_column: 'is_active'
{%- endset -%}

{{ datavault4dbt.ref_table(yaml_metadata=yaml_metadata) }}
