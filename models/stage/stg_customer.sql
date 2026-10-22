{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 'src_customer'
ldts: 'ldts'
rsrc: 'rsrc'
hashed_columns:
    hk_customer_h:
        - c_custkey
    hk_nation_h:
        - c_nationkey
    hk_customer_nation_l:
        - c_custkey
        - c_nationkey
    hd_customer_n_s:
        is_hashdiff: true
        columns:
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
derived_columns:
    country_code:
        value: '!INTL'
        datatype: 'STRING'
prejoined_columns:
    n_name:
        ref_model: 'src_nation_latest'
        bk: 'n_name'
        this_column_name: 'c_nationkey'
        ref_column_name: 'n_nationkey'
{%- endset -%}

{{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}
