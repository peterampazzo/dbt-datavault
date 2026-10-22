{{ config(materialized='incremental', on_schema_change=var('scn_osc', 'ignore')) }}

{%- set yaml_metadata -%}
parent_hashkey: 'hk_customer_h'
src_hashdiff: 'hd_customer_n_s'
src_payload:
    {%- if var('scn_sat_add_col', false) %}
    - c_name
    {%- endif %}
    - c_address
    - c_phone
    - c_acctbal
    - c_mktsegment
    - c_comment
    {%- if not var('scn_sat_drop_col', false) %}
    - c_nationkey
    {%- endif %}
source_model: 'stg_customer'
{%- endset -%}

{{ datavault4dbt.sat_v0(yaml_metadata=yaml_metadata) }}
