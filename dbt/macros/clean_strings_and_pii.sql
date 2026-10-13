{% macro generate_surrogate_key_bq(columns) %}
    {#-
        Deterministic BigQuery Surrogate Key Generator using TO_HEX(MD5(...))
    -#}
    TO_HEX(MD5(
        {%- for col in columns -%}
            COALESCE(CAST({{ col }} AS STRING), '')
            {%- if not loop.last %} || '|' || {% endif -%}
        {%- endfor -%}
    ))
{% endmacro %}


{% macro clean_string_bq(column_name) %}
    {#-
        Standardizes string columns in BigQuery: trims whitespace and converts empty strings to NULL.
    -#}
    NULLIF(TRIM(CAST({{ column_name }} AS STRING)), '')
{% endmacro %}
