{{
    config(
        materialized = "incremental",
        incremental_strategy = "merge",
        unique_key = "daily_sales_sk",
        partition_by = {
            "field": "order_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by = ["brand", "brand_tier"],
        require_partition_filter = true,
        labels = {
            "layer": "adl_bi",
            "domain": "commercial_bi",
            "finops_optimized": "true"
        }
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- bi.fact_daily_sales
-- Daily sales time series for executive trend analysis & Looker Studio dashboards
-- BigQuery FinOps: Partitioned by order_date (DAY), clustered by (brand, brand_tier),
-- incremental MERGE strategy with require_partition_filter = true
------------------------------------------------------------------------------------------------------------------------
SELECT
    TO_HEX(MD5(CAST(o.order_date AS STRING) || '|' || o.brand)) AS daily_sales_sk,
    o.order_date,
    o.brand,
    b.brand_tier,
    o.order_year,
    o.order_month,
    o.order_day_of_week,
    COUNT(*)                            AS order_count,
    SUM(o.total_amount)                 AS daily_revenue,
    SUM(o.net_revenue)                  AS daily_net_revenue,
    ROUND(AVG(o.total_amount), 2)       AS avg_order_value,
    SUM(o.item_count)                   AS items_sold,
    COUNT(DISTINCT o.customer_sk)       AS unique_customers
FROM {{ ref('fact_orders') }} o
LEFT JOIN {{ ref('map_brand') }} b ON o.brand = b.brand
WHERE {{ enforce_partition_filter('o.order_date') }}
GROUP BY 1, 2, 3, 4, 5, 6, 7
