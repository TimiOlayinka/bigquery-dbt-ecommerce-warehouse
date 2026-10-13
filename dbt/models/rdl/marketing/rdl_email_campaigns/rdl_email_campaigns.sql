{{
    config(
        materialized = "view",
        tags = ["rdl", "marketing"]
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- rdl_marketing.rdl_email_campaigns
-- Deduplicated marketing staging view over BigQuery external/history table
------------------------------------------------------------------------------------------------------------------------
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY campaign_id, date_nk, brand
            ORDER BY ingest_date DESC
        ) AS rn
    FROM {{ source('rdl_marketing', 'email_campaigns_history') }}
)
SELECT * EXCEPT(rn)
FROM ranked
WHERE rn = 1
