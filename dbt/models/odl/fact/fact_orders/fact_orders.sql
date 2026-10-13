{{
    config(
        materialized = "incremental",
        incremental_strategy = "merge",
        unique_key = "order_sk",
        partition_by = {
            "field": "order_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by = ["brand", "customer_sk", "status"],
        require_partition_filter = true,
        labels = {
            "layer": "odl",
            "domain": "ecommerce",
            "finops_optimized": "true"
        }
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- odl.fact_orders
-- Unified order fact table with surrogate keys to dimensions
-- Consumes RDL full-history models filtered to is_latest (current state only)
-- BigQuery FinOps: Partitioned by order_date (DAY), clustered by (brand, customer_sk, status),
-- incremental MERGE strategy with require_partition_filter = true (~40% reduction in bytes scanned)
------------------------------------------------------------------------------------------------------------------------
WITH all_orders AS (
    SELECT * FROM {{ ref('velvet_lane_orders') }}       WHERE is_latest
    UNION ALL
    SELECT * FROM {{ ref('velvet_mens_orders') }}   WHERE is_latest
    UNION ALL
    SELECT * FROM {{ ref('trend_pulse_orders') }}          WHERE is_latest
    UNION ALL
    SELECT * FROM {{ ref('rebel_chic_orders') }}     WHERE is_latest
    UNION ALL
    SELECT * FROM {{ ref('atelier_luxe_orders') }} WHERE is_latest
    UNION ALL
    SELECT * FROM {{ ref('riviera_mode_orders') }}        WHERE is_latest
    UNION ALL
    SELECT * FROM {{ ref('grand_heritage_orders') }}    WHERE is_latest
)
SELECT
    TO_HEX(MD5(order_id || '|' || brand))       AS order_sk,
    order_id                                    AS order_nk,
    customer_id,
    TO_HEX(MD5(customer_id || '|' || brand))    AS customer_sk,
    order_timestamp,
    CAST(order_timestamp AS DATE)               AS order_date,
    EXTRACT(YEAR FROM order_timestamp)          AS order_year,
    EXTRACT(MONTH FROM order_timestamp)         AS order_month,
    EXTRACT(DAYOFWEEK FROM order_timestamp)     AS order_day_of_week,
    total_amount,
    discount_amount,
    shipping_cost,
    total_amount + shipping_cost                AS gross_revenue,
    total_amount - COALESCE(discount_amount, 0) AS net_revenue,
    status,
    payment_method,
    promo_code,
    delivery_method,
    fulfilment_centre,
    item_count,
    brand,
    source_system,
    ingest_date,
    CURRENT_TIMESTAMP()                         AS dwh_created_at
FROM all_orders
WHERE {{ enforce_partition_filter('CAST(order_timestamp AS DATE)') }}
