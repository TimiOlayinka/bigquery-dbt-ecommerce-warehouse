{{
    config(
        materialized = "view",
        tags = ["rdl", "marketing"]
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.rdl_meta_ads
-- Deduplicated marketing staging view over BigQuery external/history table
------------------------------------------------------------------------------------------------------------------------
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY campaign_id, publisher_platform, date_nk, brand
            ORDER BY ingest_date DESC
        ) AS rn
    FROM {{ source('rdl_marketing', 'meta_ads_history') }}
)
SELECT * EXCEPT(rn)
FROM ranked
WHERE rn = 1
