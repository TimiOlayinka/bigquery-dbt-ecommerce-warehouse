------------------------------------------------------------------------------------------------------------------------
-- rdl_boohoo_commerce.boohoo_man_orders
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
order_id,
        customer_id,
        order_date AS order_timestamp,
        order_total AS total_amount,
        order_status AS status,
        payment_method,
        discount_amount,
        shipping_cost,
        item_count,
        promo_code,
        delivery_method,
        warehouse_id AS fulfilment_centre,
        ingest_date,
        CAST(REPLACE(SPLIT(ingest_time, '+')[OFFSET(0)], 'T', ' ') AS TIMESTAMP) AS ingest_ts
    FROM {{ source('rdl_boohoo_commerce', 'boohoo_man_orders_history') }}
),
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY order_id
        ) AS version_count,
        TO_HEX(MD5(
            COALESCE(CAST(order_id AS STRING), '') || '|' ||
            COALESCE(CAST(customer_id AS STRING), '') || '|' ||
            COALESCE(CAST(order_timestamp AS STRING), '') || '|' ||
            COALESCE(CAST(total_amount AS STRING), '') || '|' ||
            COALESCE(CAST(status AS STRING), '') || '|' ||
            COALESCE(CAST(payment_method AS STRING), '') || '|' ||
            COALESCE(CAST(discount_amount AS STRING), '') || '|' ||
            COALESCE(CAST(shipping_cost AS STRING), '') || '|' ||
            COALESCE(CAST(item_count AS STRING), '') || '|' ||
            COALESCE(CAST(promo_code AS STRING), '') || '|' ||
            COALESCE(CAST(delivery_method AS STRING), '') || '|' ||
            COALESCE(CAST(fulfilment_centre AS STRING), '')
        )) AS record_hash
    FROM history
)
SELECT
    order_id,
    customer_id,
    CAST(order_timestamp AS TIMESTAMP) AS order_timestamp,
    total_amount,
    status,
    payment_method,
    discount_amount,
    shipping_cost,
    item_count,
    promo_code,
    delivery_method,
    fulfilment_centre,
    ingest_date,
    ingest_ts,
    'Boohoo Man' AS brand,
    'boohoo_commerce' AS source_system,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
