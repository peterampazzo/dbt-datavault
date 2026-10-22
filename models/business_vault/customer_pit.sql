{{ config(materialized='incremental',
        post_hook="{{ datavault4dbt.clean_up_pit('control_snap_v1') }}") }}

{%- set yaml_metadata -%}
pit_type: '!Regular PIT'
tracked_entity: 'customer_h'
hashkey: 'hk_customer_h'
sat_names:
    - customer_n_s
    - customer_phone_ma_s
snapshot_relation: 'control_snap_v1'
snapshot_trigger_column: 'is_active'
dimension_key: 'hk_customer_d'
custom_rsrc: 'PIT table for TPC_H customers'
{%- endset -%}

{{ datavault4dbt.pit(yaml_metadata=yaml_metadata) }}
