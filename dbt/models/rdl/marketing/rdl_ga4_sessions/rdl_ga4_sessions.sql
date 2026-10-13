{{
    config(
        materialized = "view",
        tags = ["rdl", "marketing"]
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.rdl_ga4_sessions
-- Deduplicated marketing staging view over BigQuery external/history table
------------------------------------------------------------------------------------------------------------------------
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY session_id, brand
            ORDER BY ingest_date DESC
        ) AS rn
    FROM {{ source('rdl_marketing', 'ga4_sessions_history') }}
)
SELECT * EXCEPT(rn)
FROM ranked
WHERE rn = 1
