{{
    config(
        materialized = "table",
        partition_by = {"field": "date_nk", "data_type": "date", "granularity": "day"},
        cluster_by = ["brand"],
        tags = ["adl", "bi", "finops_partitioned"]
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- bi.fact_channel_performance
-- Cross-channel benchmarking — normalised metrics across all marketing channels
-- Designed for client-facing channel comparison dashboards
------------------------------------------------------------------------------------------------------------------------
WITH meta AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        'Meta Ads' AS channel,
        'Paid Social' AS channel_type,
        SUM(spend) AS spend,
        SUM(impressions) AS impressions,
        SUM(clicks) AS clicks,
        SUM(reach) AS reach,
        0 AS conversions,
        CAST(0 AS NUMERIC) AS revenue,
        0 AS sessions
    FROM {{ ref('fact_meta_campaign_insights') }}
    GROUP BY 1, 2, 3
),
google AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        'Google Ads' AS channel,
        'Paid Search' AS channel_type,
        SUM(spend),
        SUM(impressions),
        SUM(clicks),
        0,
        SUMCAST((conversions) AS INT64),
        SUM(conversions_value),
        0
    FROM {{ ref('fact_google_ads_performance') }}
    GROUP BY 1, 2, 3
),
tiktok AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        'TikTok Ads' AS channel,
        'Paid Social' AS channel_type,
        SUM(spend),
        SUM(impressions),
        SUM(clicks),
        SUM(reach),
        SUMCAST((conversion) AS INT64),
        CAST(0 AS NUMERIC),
        0
    FROM {{ ref('fact_tiktok_ad_insights') }}
    GROUP BY 1, 2, 3
),
email AS CAST((
    SELECT
        date_nk,
        brand,
        brand_tier,
        'Email' AS channel,
        'Owned' AS channel_type,
        CAST(0 AS NUMERIC),
        SUM(delivered) AS INT64),
        SUMCAST((clicked) AS INT64),
        SUMCAST((delivered) AS INT64),
        SUMCAST((converted) AS INT64),
        SUM(revenue),
        0
    FROM {{ ref('fact_email_engagement') }}
    GROUP BY 1, 2, 3
),
influencer AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        'Influencer' AS channel,
        'Earned' AS channel_type,
        SUM(cost),
        SUM(impressions),
        SUMCAST((link_clicks) AS INT64),
        SUM(reach),
        SUMCAST((conversions) AS INT64),
        SUM(revenue_attributed),
        0
    FROM {{ ref('fact_influencer_performance') }}
    GROUP BY 1, 2, 3
),
ga4 AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        'Website (GA4)' AS channel,
        'All Traffic' AS channel_type,
        CAST(0 AS NUMERIC),
        CAST(0 AS INT64),
        CAST(0 AS INT64),
        CAST(0 AS INT64),
        SUMCAST((transactions) AS INT64),
        SUM(revenue),
        COUNT(*) AS sessions
    FROM {{ ref('fact_ga4_sessions') }}
    GROUP BY 1, 2, 3
),
combined AS (
    SELECT * FROM meta UNION ALL SELECT * FROM google UNION ALL SELECT * FROM tiktok
    UNION ALL SELECT * FROM email UNION ALL SELECT * FROM influencer UNION ALL SELECT * FROM ga4
)
SELECT
    date_nk,
    EXTRACT(YEAR FROM date_nk)                          AS year,
    EXTRACT(MONTH FROM date_nk)                         AS month,
    brand,
    brand_tier,
    channel,
    channel_type,
    spend,
    impressions,
    clicks,
    reach,
    conversions,
    revenue,
    sessions,
    -- Normalised metrics
    ROUND(spend / NULLIF(impressions, 0) * 1000, 2)     AS cpm,
    ROUND(spend / NULLIF(clicks, 0), 2)                 AS cpc,
    ROUND(CAST(clicks AS FLOAT64) / NULLIF(impressions, 0) * 100, 4) AS ctr,
    ROUND(CAST(conversions AS FLOAT64) / NULLIF(clicks, 0) * 100, 2) AS conversion_rate,
    ROUND(spend / NULLIF(conversions, 0), 2)            AS cost_per_conversion,
    ROUND(revenue / NULLIF(spend, 0), 2)                AS roas
FROM combined
