{{ config(materialized='incremental',
        post_hook="{{ datavault4dbt.clean_up_pit('control_snap_v1_bounded') }}") }}

{%- set yaml_metadata -%}
tracked_entity: 'customer_h'
hashkey: 'hk_customer_h'
sat_names:
    - customer_n_s_v1
    - customer_phone_ma_s_ng_v1
snapshot_relation: 'control_snap_v1_bounded'
snapshot_trigger_column: 'is_active'
dimension_key: 'hk_customer_d'
refer_to_ghost_records: false
{%- endset -%}

{{ datavault4dbt.pit(yaml_metadata=yaml_metadata) }}
