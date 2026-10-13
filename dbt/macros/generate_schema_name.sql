{% macro generate_schema_name(custom_schema_name, node) -%}
    {#-
        BigQuery Multi-Environment Dataset Resolution:
        - In 'prod': writes directly to the target medallion dataset (e.g. `rdl_boohoo_commerce`, `odl`, `bi`)
        - In 'ci': prefixes with the ephemeral PR schema (e.g. `ci_pr_42_odl`) for isolated Slim CI validation
        - In 'dev': prefixes with the developer's sandbox dataset (e.g. `odl_dev_bi`)
    -#}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- elif target.name == 'prod' -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
