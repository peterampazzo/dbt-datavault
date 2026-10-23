{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 'src_customer_phone'
ldts: 'ldts'
rsrc: 'rsrc'
enable_ghost_records: false
multi_active_config:
    multi_active_key: 'phone_type'
    main_hashkey_column: 'hk_customer_h'
hashed_columns:
    hk_customer_h:
        - c_custkey
    hd_customer_phone_ma_s:
        is_hashdiff: true
        columns:
            - phone_number
{%- endset -%}

{{ datavault4dbt.stage(yaml_metadata=yaml_metadata) }}
