{{
    config(
        materialized = "incremental",
        incremental_strategy = "merge",
        unique_key = "campaign_perf_sk",
        partition_by = {
            "field": "date_nk",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by = ["brand", "channel", "campaign_type"],
        require_partition_filter = true,
        labels = {
            "layer": "adl_bi",
            "domain": "marketing_bi",
            "finops_optimized": "true"
        }
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- bi.fact_campaign_performance
-- Campaign-level deep-dive — top/bottom campaigns by spend, ROAS, conversions
-- BigQuery FinOps: Partitioned by date_nk (DAY), clustered by (brand, channel, campaign_type),
-- incremental MERGE strategy with require_partition_filter = true
------------------------------------------------------------------------------------------------------------------------
WITH meta_campaigns AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        meta_campaign_name                              AS campaign_name,
        campaign_type,
        'Meta Ads'                                      AS channel,
        objective,
        SUM(spend)                                      AS spend,
        SUM(impressions)                                AS impressions,
        SUM(clicks)                                     AS clicks,
        SUM(reach)                                      AS reach,
        0                                               AS conversions,
        CAST(0 AS NUMERIC)                              AS conversions_value
    FROM {{ ref('fact_meta_campaign_insights') }}
    WHERE {{ enforce_partition_filter('date_nk') }}
    GROUP BY 1, 2, 3, 4, 5, 7
),
google_campaigns AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        google_ads_campaign_name                        AS campaign_name,
        channel_group                                   AS campaign_type,
        'Google Ads'                                    AS channel,
        channel_type                                    AS objective,
        SUM(spend)                                      AS spend,
        SUM(impressions)                                AS impressions,
        SUM(clicks)                                     AS clicks,
        0                                               AS reach,
        CAST(SUM(conversions) AS INT64)                 AS conversions,
        SUM(conversions_value)                          AS conversions_value
    FROM {{ ref('fact_google_ads_performance') }}
    WHERE {{ enforce_partition_filter('date_nk') }}
    GROUP BY 1, 2, 3, 4, 5, 7
),
tiktok_campaigns AS (
    SELECT
        date_nk,
        brand,
        brand_tier,
        tiktok_campaign_name                            AS campaign_name,
        'TikTok'                                        AS campaign_type,
        'TikTok Ads'                                    AS channel,
        objective,
        SUM(spend)                                      AS spend,
        SUM(impressions)                                AS impressions,
        SUM(clicks)                                     AS clicks,
        SUM(reach)                                      AS reach,
        CAST(SUM(conversion) AS INT64)                  AS conversions,
        CAST(0 AS NUMERIC)                              AS conversions_value
    FROM {{ ref('fact_tiktok_ad_insights') }}
    WHERE {{ enforce_partition_filter('date_nk') }}
    GROUP BY 1, 2, 3, 4, 5, 7
),
all_campaigns AS (
    SELECT * FROM meta_campaigns
    UNION ALL SELECT * FROM google_campaigns
    UNION ALL SELECT * FROM tiktok_campaigns
)
SELECT
    TO_HEX(MD5(CAST(date_nk AS STRING) || '|' || brand || '|' || channel || '|' || COALESCE(campaign_name, ''))) AS campaign_perf_sk,
    date_nk,
    EXTRACT(YEAR FROM date_nk)                          AS year,
    EXTRACT(MONTH FROM date_nk)                         AS month,
    brand,
    brand_tier,
    campaign_name,
    campaign_type,
    channel,
    objective,
    spend,
    impressions,
    clicks,
    reach,
    conversions,
    conversions_value,
    -- Performance metrics
    ROUND(spend / NULLIF(impressions, 0) * 1000, 2)                     AS cpm,
    ROUND(spend / NULLIF(clicks, 0), 2)                                 AS cpc,
    ROUND(CAST(clicks AS FLOAT64) / NULLIF(impressions, 0) * 100, 4)    AS ctr,
    ROUND(CAST(conversions AS FLOAT64) / NULLIF(clicks, 0) * 100, 2)    AS conversion_rate,
    ROUND(spend / NULLIF(conversions, 0), 2)                            AS cost_per_conversion,
    ROUND(conversions_value / NULLIF(spend, 0), 2)                      AS roas
FROM all_campaigns
