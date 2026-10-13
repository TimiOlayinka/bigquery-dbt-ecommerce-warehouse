{{
    config(
        materialized = "view",
        tags = ["rdl"]
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- rdl_oracle_commerce.grand_heritage_customers
-- Full-history model: ALL versions preserved, use WHERE is_latest for current state
-- Pattern: history → versioned (ROW_NUMBER + COUNT + MD5) → SELECT ALL (no filter)
------------------------------------------------------------------------------------------------------------------------
WITH history AS (
    SELECT
profile_id AS customer_id,
        email_address AS email,
        first_name,
        last_name,
        phone_number AS phone,
        city,
        country,
        customer_segment,
        registration_date AS signup_date,
        gender,
        receive_email AS is_subscribed,
        ingest_date,
        CAST(REPLACE(SPLIT(ingest_time, '+')[SAFE_OFFSET(0)], 'T', ' ') AS TIMESTAMP) AS ingest_ts
    FROM {{ source('rdl_oracle_commerce', 'grand_heritage_customers_history') }}
),
versioned AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY customer_id
        ) AS version_count,
        TO_HEX(MD5(
            COALESCE(CAST(customer_id AS STRING), '') || '|' ||
            COALESCE(CAST(email AS STRING), '') || '|' ||
            COALESCE(CAST(first_name AS STRING), '') || '|' ||
            COALESCE(CAST(last_name AS STRING), '') || '|' ||
            COALESCE(CAST(phone AS STRING), '') || '|' ||
            COALESCE(CAST(city AS STRING), '') || '|' ||
            COALESCE(CAST(country AS STRING), '') || '|' ||
            COALESCE(CAST(customer_segment AS STRING), '') || '|' ||
            COALESCE(CAST(signup_date AS STRING), '') || '|' ||
            COALESCE(CAST(gender AS STRING), '') || '|' ||
            COALESCE(CAST(is_subscribed AS STRING), '')
        )) AS record_hash
    FROM history
)
SELECT
    customer_id,
    email,
    first_name,
    last_name,
    phone,
    city,
    country,
    customer_segment,
    CAST(signup_date AS DATE) AS registration_date,
    gender,
    CAST(is_subscribed AS BOOL) AS is_marketing_opted_in,
    ingest_date,
    ingest_ts,
    'GrandHeritage' AS brand,
    'oracle_commerce' AS source_system,
    row_version,
    row_version = 1 AS is_latest,
    version_count,
    record_hash
FROM versioned
