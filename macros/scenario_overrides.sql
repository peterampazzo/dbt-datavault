{#
    SCENARIO EXPERIMENT - not a recommendation.
    Overrides the adapter's alter_relation_add_remove_columns to test whether
    Delta column mapping + ALTER TABLE ... DROP COLUMN works on Fabric Spark
    (the stock adapter macro raises a compiler error instead).
    Default (scn_allow_delta_drop unset/false): same behaviour as the stock
    fabricspark__ macro in dbt-fabricspark 1.13.7, except that the
    `alter table ... add columns` statement is only issued when add_columns is
    non-empty (the stock macro emits a bare `alter table <rel>` otherwise,
    which fails with PARSE_SYNTAX_ERROR on Fabric Spark).
#}

{% macro fabricspark__alter_relation_add_remove_columns(relation, add_columns, remove_columns) %}

  {% if remove_columns %}
    {% if not var('scn_allow_delta_drop', false) %}
      {% if relation.is_delta %}
        {{ exceptions.raise_compiler_error('Delta tables does not support dropping columns from tables') }}
      {% endif %}
    {% endif %}
  {% endif %}

  {% if add_columns is none %}
    {% set add_columns = [] %}
  {% endif %}

  {% if remove_columns and var('scn_allow_delta_drop', false) %}
    {% set cm_sql -%}
      alter {{ relation.type }} {{ relation }} set tblproperties
        ('delta.columnMapping.mode'='name','delta.minReaderVersion'='2','delta.minWriterVersion'='5')
    {%- endset %}
    {% do run_query(cm_sql) %}
    {% set drop_sql -%}
      alter {{ relation.type }} {{ relation }}
        drop columns
        {% for column in remove_columns %}
           {{ column.name }}{{ ',' if not loop.last }}
        {% endfor %}
    {%- endset %}
    {% do run_query(drop_sql) %}
  {% endif %}

  {% if add_columns %}
    {% set sql -%}

       alter {{ relation.type }} {{ relation }}

         add columns
            {% for column in add_columns %}
               {{ column.name }} {{ column.data_type }}{{ ',' if not loop.last }}
            {% endfor %}

    {%- endset -%}

    {% do run_query(sql) %}
  {% endif %}

{% endmacro %}
