{{
    config(
        materialized = "view",
        tags = ["rdl", "marketing"]
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.rdl_tiktok_ads
-- Deduplicated marketing staging view over BigQuery external/history table
------------------------------------------------------------------------------------------------------------------------
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ad_id, date_nk, brand
            ORDER BY ingest_date DESC
        ) AS rn
    FROM {{ source('rdl_marketing', 'tiktok_ads_history') }}
)
SELECT * EXCEPT(rn)
FROM ranked
WHERE rn = 1
