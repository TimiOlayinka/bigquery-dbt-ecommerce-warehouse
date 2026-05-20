------------------------------------------------------------------------------------------------------------------------
-- rdl_oracle_commerce.debenhams_products
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
item_id AS product_id,
        display_name AS product_name,
        colour_code AS colour,
        category_code AS category,
        sub_category_code AS subcategory,
        list_price AS current_price,
        unit_cost AS cost_price,
        rrp,
        fabric_type AS material,
        season_year AS season,
        is_active,
        stock_status,
        created_at,
        updated_at,
        ingest_date,
        CAST(REPLACE(SPLIT(ingest_time, '+')[OFFSET(0)], 'T', ' ') AS TIMESTAMP) AS ingest_ts
    FROM {{ source('rdl_oracle_commerce', 'debenhams_products_history') }}
),
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY product_id
        ) AS version_count,
        TO_HEX(MD5(
            COALESCE(CAST(product_id AS STRING), '') || '|' ||
            COALESCE(CAST(product_name AS STRING), '') || '|' ||
            COALESCE(CAST(colour AS STRING), '') || '|' ||
            COALESCE(CAST(category AS STRING), '') || '|' ||
            COALESCE(CAST(subcategory AS STRING), '') || '|' ||
            COALESCE(CAST(current_price AS STRING), '') || '|' ||
            COALESCE(CAST(cost_price AS STRING), '') || '|' ||
            COALESCE(CAST(rrp AS STRING), '') || '|' ||
            COALESCE(CAST(material AS STRING), '') || '|' ||
            COALESCE(CAST(season AS STRING), '') || '|' ||
            COALESCE(CAST(is_active AS STRING), '') || '|' ||
            COALESCE(CAST(stock_status AS STRING), '') || '|' ||
            COALESCE(CAST(created_at AS STRING), '') || '|' ||
            COALESCE(CAST(updated_at AS STRING), '')
        )) AS record_hash
    FROM history
)
SELECT
    product_id,
    product_name,
    colour,
    category,
    subcategory,
    current_price,
    cost_price,
    rrp,
    material,
    season,
    CAST(is_active AS BOOL) AS is_active,
    stock_status,
    created_at,
    updated_at,
    ingest_date,
    ingest_ts,
    'Debenhams' AS brand,
    'oracle_commerce' AS source_system,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
