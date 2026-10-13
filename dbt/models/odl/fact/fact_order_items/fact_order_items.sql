{{
    config(
        materialized = "incremental",
        incremental_strategy = "merge",
        unique_key = "order_item_sk",
        partition_by = {
            "field": "order_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by = ["brand", "product_sk", "order_sk"],
        require_partition_filter = true,
        labels = {
            "layer": "odl",
            "domain": "ecommerce",
            "finops_optimized": "true"
        }
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- odl.fact_order_items
-- Granular line-item order fact table across all 7 OmniStyle Commerce Group brands
-- BigQuery FinOps: Partitioned by order_date (DAY), clustered by (brand, product_sk, order_sk),
-- incremental MERGE with require_partition_filter = true (reduces scanned bytes by ~40%+)
------------------------------------------------------------------------------------------------------------------------
WITH all_order_items AS (
    SELECT
        order_item_id,
        order_id,
        product_id,
        customer_id,
        CAST(order_date AS TIMESTAMP)           AS order_timestamp,
        CAST(order_date AS DATE)                AS order_date,
        CAST(quantity AS INT64)                 AS quantity,
        CAST(unit_price AS NUMERIC)             AS unit_price,
        CAST(discount_amount AS NUMERIC)        AS item_discount_amount,
        'VelvetLane'                                AS brand,
        'omnia_commerce'                       AS source_system,
        CAST(ingest_date AS DATE)               AS ingest_date
    FROM {{ source('rdl_omnia_commerce', 'velvet_lane_order_items_history') }}
    WHERE {{ enforce_partition_filter('CAST(order_date AS DATE)') }}

    UNION ALL

    SELECT
        order_item_id,
        order_id,
        product_id,
        customer_id,
        CAST(order_date AS TIMESTAMP)           AS order_timestamp,
        CAST(order_date AS DATE)                AS order_date,
        CAST(quantity AS INT64)                 AS quantity,
        CAST(unit_price AS NUMERIC)             AS unit_price,
        CAST(discount_amount AS NUMERIC)        AS item_discount_amount,
        'VelvetMens'                            AS brand,
        'omnia_commerce'                       AS source_system,
        CAST(ingest_date AS DATE)               AS ingest_date
    FROM {{ source('rdl_omnia_commerce', 'velvet_mens_order_items_history') }}
    WHERE {{ enforce_partition_filter('CAST(order_date AS DATE)') }}

    UNION ALL

    SELECT
        order_item_id,
        order_id,
        product_id,
        customer_id,
        CAST(order_date AS TIMESTAMP)           AS order_timestamp,
        CAST(order_date AS DATE)                AS order_date,
        CAST(quantity AS INT64)                 AS quantity,
        CAST(unit_price AS NUMERIC)             AS unit_price,
        CAST(discount_amount AS NUMERIC)        AS item_discount_amount,
        'TrendPulse'                     AS brand,
        'salesforce_commerce'                   AS source_system,
        CAST(ingest_date AS DATE)               AS ingest_date
    FROM {{ source('rdl_salesforce_commerce', 'trend_pulse_order_items_history') }}
    WHERE {{ enforce_partition_filter('CAST(order_date AS DATE)') }}

    UNION ALL

    SELECT
        order_item_id,
        order_id,
        product_id,
        customer_id,
        CAST(order_date AS TIMESTAMP)           AS order_timestamp,
        CAST(order_date AS DATE)                AS order_date,
        CAST(quantity AS INT64)                 AS quantity,
        CAST(unit_price AS NUMERIC)             AS unit_price,
        CAST(discount_amount AS NUMERIC)        AS item_discount_amount,
        'RebelChic'                              AS brand,
        'shopify'                               AS source_system,
        CAST(ingest_date AS DATE)               AS ingest_date
    FROM {{ source('rdl_shopify', 'rebel_chic_order_items_history') }}
    WHERE {{ enforce_partition_filter('CAST(order_date AS DATE)') }}

    UNION ALL

    SELECT
        order_item_id,
        order_id,
        product_id,
        customer_id,
        CAST(order_date AS TIMESTAMP)           AS order_timestamp,
        CAST(order_date AS DATE)                AS order_date,
        CAST(quantity AS INT64)                 AS quantity,
        CAST(unit_price AS NUMERIC)             AS unit_price,
        CAST(discount_amount AS NUMERIC)        AS item_discount_amount,
        'AtelierLuxe'                          AS brand,
        'magento'                               AS source_system,
        CAST(ingest_date AS DATE)               AS ingest_date
    FROM {{ source('rdl_magento', 'atelier_luxe_order_items_history') }}
    WHERE {{ enforce_partition_filter('CAST(order_date AS DATE)') }}

    UNION ALL

    SELECT
        order_item_id,
        order_id,
        product_id,
        customer_id,
        CAST(order_date AS TIMESTAMP)           AS order_timestamp,
        CAST(order_date AS DATE)                AS order_date,
        CAST(quantity AS INT64)                 AS quantity,
        CAST(unit_price AS NUMERIC)             AS unit_price,
        CAST(discount_amount AS NUMERIC)        AS item_discount_amount,
        'RivieraMode'                                 AS brand,
        'magento'                               AS source_system,
        CAST(ingest_date AS DATE)               AS ingest_date
    FROM {{ source('rdl_magento', 'riviera_mode_order_items_history') }}
    WHERE {{ enforce_partition_filter('CAST(order_date AS DATE)') }}

    UNION ALL

    SELECT
        order_item_id,
        order_id,
        product_id,
        customer_id,
        CAST(order_date AS TIMESTAMP)           AS order_timestamp,
        CAST(order_date AS DATE)                AS order_date,
        CAST(quantity AS INT64)                 AS quantity,
        CAST(unit_price AS NUMERIC)             AS unit_price,
        CAST(discount_amount AS NUMERIC)        AS item_discount_amount,
        'GrandHeritage'                             AS brand,
        'oracle_commerce'                       AS source_system,
        CAST(ingest_date AS DATE)               AS ingest_date
    FROM {{ source('rdl_oracle_commerce', 'grand_heritage_order_items_history') }}
    WHERE {{ enforce_partition_filter('CAST(order_date AS DATE)') }}
),
deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_item_id, brand
            ORDER BY ingest_date DESC
        ) AS rn
    FROM all_order_items
)
SELECT
    TO_HEX(MD5(order_item_id || '|' || brand))                          AS order_item_sk,
    order_item_id                                                       AS order_item_nk,
    TO_HEX(MD5(order_id || '|' || brand))                               AS order_sk,
    TO_HEX(MD5(product_id || '|' || brand))                             AS product_sk,
    TO_HEX(MD5(customer_id || '|' || brand))                            AS customer_sk,
    order_id,
    product_id,
    customer_id,
    order_timestamp,
    order_date,
    quantity,
    unit_price,
    COALESCE(item_discount_amount, 0)                                   AS item_discount_amount,
    ROUND(quantity * unit_price, 2)                                     AS gross_item_revenue,
    ROUND((quantity * unit_price) - COALESCE(item_discount_amount, 0), 2) AS net_item_revenue,
    brand,
    source_system,
    ingest_date,
    CURRENT_TIMESTAMP()                                                 AS dwh_created_at
FROM deduped
WHERE rn = 1
