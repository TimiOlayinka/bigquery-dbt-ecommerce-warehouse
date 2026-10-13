{% macro enforce_partition_filter(column_name, lookback_days=var('incremental_lookback_days', 3)) %}
    {#-
        BigQuery FinOps Incremental & Partition Pruning Macro:
        Ensures incremental MERGE runs only scan the rolling lookback window
        on the upstream partitioned table, reducing bytes scanned by ~40%+.
    -#}
    {% if is_incremental() %}
        {{ column_name }} >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ lookback_days }} DAY)
    {% else %}
        TRUE
    {% endif %}
{% endmacro %}


{% macro audit_bigquery_table_options(partition_field, cluster_fields) %}
    {#-
        Helper macro returning standardized BigQuery FinOps config metadata
        for partitioned and clustered fact tables.
    -#}
    {{ return({
        "partition_by": {
            "field": partition_field,
            "data_type": "date",
            "granularity": "day"
        },
        "cluster_by": cluster_fields,
        "require_partition_filter": true
    }) }}
{% endmacro %}
