{{ config(materialized='incremental') }}

{%- set yaml_metadata -%}
tracked_hashkey: hk_customer_nation_l
is_active_alias: 'is_current_rel'
source_model: stg_customer
source_is_single_batch: true
{%- endset -%}

{{ datavault4dbt.eff_sat_v0(yaml_metadata=yaml_metadata) }}
