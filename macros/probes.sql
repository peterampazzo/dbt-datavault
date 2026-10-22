{% macro probe_schema_setup() %}
  {% set r = run_query("CREATE SCHEMA IF NOT EXISTS dv_test") %}
  {{ print("schema setup ok: " ~ r) }}
{% endmacro %}

{% macro probe_version() %}
  {% for row in run_query("SELECT version() AS spark_version").rows %}
    {{ print("version: " ~ row[0]) }}
  {% endfor %}
  {% for row in run_query("SET spark.databricks.delta.properties.defaults.columnMapping.mode").rows %}
    {{ print("colmapping-default: " ~ row[0] ~ " = " ~ row[1]) }}
  {% endfor %}
{% endmacro %}

{% macro probe_qualify() %}
  {{ print(run_query("CREATE OR REPLACE TABLE dv_test.probe_q AS SELECT * FROM VALUES (1,'a',1),(1,'b',2),(2,'c',1) AS t(hk, v, ldts)")) }}
  {{ print("QUALIFY result:") }}
  {{ print(run_query("SELECT * FROM dv_test.probe_q QUALIFY ROW_NUMBER() OVER (PARTITION BY hk ORDER BY ldts) = 1")) }}
{% endmacro %}

{% macro probe_qualify_cte() %}
  {{ print(run_query("CREATE OR REPLACE TABLE dv_test.probe_q AS SELECT * FROM VALUES (1,'a',1),(1,'b',2),(2,'c',1) AS t(hk, v, ldts)")) }}
  {{ print("CTE fallback result:") }}
  {{ print(run_query("WITH probe_q_prep AS (SELECT hk, v, ldts, ROW_NUMBER() OVER (PARTITION BY hk ORDER BY ldts) AS rn FROM dv_test.probe_q) SELECT hk, v, ldts FROM probe_q_prep WHERE rn = 1")) }}
{% endmacro %}

{% macro probe_column_mapping() %}
  {{ print(run_query("CREATE OR REPLACE TABLE dv_test.probe_cm (hk INT, val STRING) USING DELTA")) }}
  {{ print("SET TBLPROPERTIES:") }}
  {{ print(run_query("ALTER TABLE dv_test.probe_cm SET TBLPROPERTIES ('delta.columnMapping.mode'='name','delta.minReaderVersion'='2','delta.minWriterVersion'='5')")) }}
  {{ print("ADD COLUMNS:") }}
  {{ print(run_query("ALTER TABLE dv_test.probe_cm ADD COLUMNS (new_col STRING)")) }}
  {{ print("RENAME COLUMN:") }}
  {{ print(run_query("ALTER TABLE dv_test.probe_cm RENAME COLUMN new_col TO renamed_col")) }}
  {{ print("DROP COLUMN:") }}
  {{ print(run_query("ALTER TABLE dv_test.probe_cm DROP COLUMN renamed_col")) }}
  {{ print("DROP COLUMN IF EXISTS (missing):") }}
  {{ print(run_query("ALTER TABLE dv_test.probe_cm DROP COLUMN IF EXISTS does_not_exist")) }}
{% endmacro %}

{% macro probe_drop_rename_column() %}
  {{ print(run_query("CREATE OR REPLACE TABLE dv_test.probe_nocm (hk INT, extra_col STRING) USING DELTA")) }}
  {{ print("RENAME COLUMN (no column mapping):") }}
  {{ print(run_query("ALTER TABLE dv_test.probe_nocm RENAME COLUMN extra_col TO renamed_col")) }}
  {{ print("DROP COLUMN (no column mapping):") }}
  {{ print(run_query("ALTER TABLE dv_test.probe_nocm DROP COLUMN renamed_col")) }}
{% endmacro %}

{% macro probe_nocm_drop_only() %}
  {{ print(run_query("CREATE OR REPLACE TABLE dv_test.probe_nocm (hk INT, extra_col STRING) USING DELTA")) }}
  {{ print("DROP COLUMN (no column mapping):") }}
  {{ print(run_query("ALTER TABLE dv_test.probe_nocm DROP COLUMN extra_col")) }}
{% endmacro %}

{% macro probe_functions() %}
  {% set t = run_query("SELECT current_timestamp() AS now_ts, TO_TIMESTAMP('0001-01-01 00:00:01','yyyy-MM-dd HH:mm:ss') AS boat, TO_TIMESTAMP('8888-12-31 23:59:59','yyyy-MM-dd HH:mm:ss') AS eoat, md5('x') AS md5x, sha2('x',256) AS sha2x, CAST(1 AS STRING) AS cast_str, upper(trim('  a ')) AS uptrim, concat_ws('||','a','b') AS cws, to_date('0001-01-01','yyyy-MM-dd') AS boat_date") %}
  {% for row in t.rows %}
    {% for i in range(t.column_names | length) %}
      {{ print(t.column_names[i] ~ " = " ~ row[i]) }}
    {% endfor %}
  {% endfor %}
{% endmacro %}

{% macro probe_casing() %}
  {{ print(run_query("CREATE OR REPLACE TABLE dv_test.probe_case (MixedCase INT, lower_case INT)")) }}
  {{ print("DESCRIBE:") }}
  {% for row in run_query("DESCRIBE dv_test.probe_case").rows %}
    {{ print("  " ~ row[0] ~ " " ~ row[1]) }}
  {% endfor %}
  {{ print("SELECT MixedCase (unquoted):") }}
  {{ print(run_query("SELECT MixedCase FROM dv_test.probe_case")) }}
  {{ print("SELECT `MixedCase` (backticked):") }}
  {{ print(run_query("SELECT `MixedCase` FROM dv_test.probe_case")) }}
  {{ print("SELECT mixedcase (lowercase):") }}
  {{ print(run_query("SELECT mixedcase FROM dv_test.probe_case")) }}
{% endmacro %}

{% macro probe_cleanup() %}
  {% for t in ['probe_q', 'probe_cm', 'probe_nocm', 'probe_case'] %}
    {{ print(run_query("DROP TABLE IF EXISTS dv_test." ~ t)) }}
  {% endfor %}
  {{ print("cleanup done") }}
{% endmacro %}

{% macro probe_counts() %}
  {% for t in ['nation_h', 'customer_h', 'customer_nation_l', 'order_nh_l', 'customer_n_s', 'customer_phone_ma_s', 'order_nh_s', 'customer_nation_es', 'customer_rts', 'currency_rh', 'currency_rs', 'customer_pit', 'control_snap_v0'] %}
    {{ print(t ~ " = " ~ run_query("SELECT COUNT(*) FROM " ~ ref(t))[0][0]) }}
  {% endfor %}
  {{ print("-- ghost rows in customer_h --") }}
  {% for row in run_query("SELECT hk_customer_h, date_format(ldts,'yyyy-MM-dd HH:mm:ss') AS l, rsrc FROM " ~ ref('customer_h') ~ " WHERE rsrc IN ('SYSTEM','ERROR') ORDER BY rsrc").rows %}
    {{ print("  " ~ row[0] ~ " | " ~ row[1] ~ " | " ~ row[2]) }}
  {% endfor %}
{% endmacro %}

{% macro probe_customer_h() %}
  {% for row in run_query("SELECT hk_customer_h, ldts, rsrc, c_custkey FROM " ~ ref('customer_h') ~ " ORDER BY ldts, c_custkey").rows %}
    {{ print("  " ~ row[0] ~ " | " ~ row[1] ~ " | " ~ row[2] ~ " | " ~ row[3]) }}
  {% endfor %}
  {{ print("-- ma_s --") }}
  {% for row in run_query("SELECT hk_customer_h, phone_type, ldts, hd_customer_phone_ma_s FROM " ~ ref('customer_phone_ma_s') ~ " ORDER BY hk_customer_h, phone_type, ldts").rows %}
    {{ print("  " ~ row[0] ~ " | " ~ row[1] ~ " | " ~ row[2] ~ " | " ~ row[3]) }}
  {% endfor %}
{% endmacro %}

{% macro probe_ts() %}
  {{ print(run_query("CREATE OR REPLACE TABLE dv_test.probe_ts AS SELECT TO_TIMESTAMP('0001-01-01 00:00:01','yyyy-MM-dd HH:mm:ss') AS ts")) }}
  {% for row in run_query("SELECT ts = TO_TIMESTAMP('0001-01-01 00:00:01','yyyy-MM-dd HH:mm:ss') AS eq, date_format(ts,'yyyy-MM-dd HH:mm:ss') AS fmt, CAST(ts AS STRING) AS s FROM dv_test.probe_ts").rows %}
    {{ print("eq=" ~ row[0] ~ " fmt=" ~ row[1] ~ " s=" ~ row[2]) }}
  {% endfor %}
  {{ print("-- ghost ldts in customer_h --") }}
  {% for row in run_query("SELECT date_format(ldts,'yyyy-MM-dd HH:mm:ss'), rsrc FROM " ~ ref('customer_h') ~ " WHERE rsrc IN ('SYSTEM','ERROR')").rows %}
    {{ print("  " ~ row[0] ~ " | " ~ row[1]) }}
  {% endfor %}
  {{ print(run_query("DROP TABLE IF EXISTS dv_test.probe_ts")) }}
{% endmacro %}

{% macro probe_placement() %}
  {% for db in ['LH_Bronze.raw', 'LH_Silver.dv_stage', 'LH_Silver.raw_vault', 'LH_Gold.business_vault'] %}
    {{ print("-- " ~ db ~ " --") }}
    {% for row in run_query("SHOW TABLES IN " ~ db).rows %}
      {{ print("  " ~ row[1]) }}
    {% endfor %}
  {% endfor %}
{% endmacro %}

{% macro probe_tblprops(relation_name) %}
  {% for row in run_query("SHOW TBLPROPERTIES " ~ ref(relation_name)).rows %}
    {{ print("  " ~ row[0] ~ " = " ~ row[1]) }}
  {% endfor %}
{% endmacro %}

{% macro probe_describe(relation_name) %}
  {% for row in run_query("DESCRIBE " ~ ref(relation_name)).rows %}
    {{ print("  " ~ row[0] ~ " " ~ row[1]) }}
  {% endfor %}
{% endmacro %}

{% macro probe_sat_counts() %}
  {% set cols = run_query("DESCRIBE " ~ ref('customer_n_s')).columns['col_name'].values() %}
  {{ print("count(*) = " ~ run_query("SELECT COUNT(*) FROM " ~ ref('customer_n_s'))[0][0]) }}
  {{ print("count(distinct hk_customer_h) = " ~ run_query("SELECT COUNT(DISTINCT hk_customer_h) FROM " ~ ref('customer_n_s'))[0][0]) }}
  {% if 'c_name' in cols %}
    {{ print("count(c_name) = " ~ run_query("SELECT COUNT(c_name) FROM " ~ ref('customer_n_s'))[0][0]) }}
  {% else %}
    {{ print("c_name: not present") }}
  {% endif %}
  {% if 'c_nationkey' in cols %}
    {{ print("count(c_nationkey) = " ~ run_query("SELECT COUNT(c_nationkey) FROM " ~ ref('customer_n_s'))[0][0]) }}
  {% else %}
    {{ print("c_nationkey: not present") }}
  {% endif %}
{% endmacro %}
