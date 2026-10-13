{{
    config(
        materialized = "incremental",
        incremental_strategy = "merge",
        partition_by = {"field": "date_nk", "data_type": "date", "granularity": "day"},
        cluster_by = ["brand"],
        require_partition_filter = true,
        tags = ["odl", "fact", "finops_partitioned"]
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- odl.fact_tiktok_ad_insights
-- Unified TikTok Ads performance with surrogate keys
-- Follows enterprise fact_tiktok_ad_insights.sql pattern
------------------------------------------------------------------------------------------------------------------------
WITH raw_data AS (
    SELECT
        ad_id                                           AS tiktok_ad_nk,
        advertiser_id                                   AS tiktok_advertiser_id,
        campaign_name                                   AS tiktok_campaign_name,
        objective,
        date_nk,
        CAST(spend AS NUMERIC),
        CAST(impressions AS INT64),
        CAST(clicks AS INT64),
        CAST(reach AS INT64),
        CAST(frequency AS NUMERIC),
        CAST(ctr AS NUMERIC),
        CAST(cpc AS NUMERIC),
        CAST(cpm AS NUMERIC),
        CAST(conversion_rate AS NUMERIC),
        CAST(conversion AS INT64),
        CAST(cost_per_conversion AS NUMERIC),
        CAST(purchase AS INT64),
        CAST(video_play_actions AS INT64),
        CAST(video_watched_2s AS INT64),
        CAST(video_watched_6s AS INT64),
        CAST(video_views_p25 AS INT64),
        CAST(video_views_p50 AS INT64),
        CAST(video_views_p75 AS INT64),
        CAST(video_views_p100 AS INT64),
        brand,
        ingest_date
    FROM {{ ref('rdl_tiktok_ads') }}
)
SELECT
    TO_HEX(MD5(rd.tiktok_ad_nk || '|' || rd.date_nk || '|' || rd.brand))
        AS tiktok_ad_sk,
    rd.tiktok_ad_nk,
    rd.tiktok_advertiser_id,
    rd.tiktok_campaign_name,
    rd.objective,
    rd.date_nk,
    EXTRACT(YEAR FROM rd.date_nk)                       AS year,
    EXTRACT(MONTH FROM rd.date_nk)                      AS month,
    rd.spend,
    rd.impressions,
    rd.clicks,
    rd.reach,
    rd.frequency,
    rd.ctr,
    rd.cpc,
    rd.cpm,
    rd.conversion_rate,
    rd.conversion,
    rd.cost_per_conversion,
    rd.purchase,
    rd.video_play_actions,
    rd.video_watched_2s,
    rd.video_watched_6s,
    rd.video_views_p25,
    rd.video_views_p50,
    rd.video_views_p75,
    rd.video_views_p100,
    rd.brand,
    b.brand_tier,
    rd.ingest_date,
    CURRENT_TIMESTAMP()                                   AS dwh_created_at
FROM raw_data rd
LEFT JOIN {{ ref('map_brand') }} b
    ON rd.brand = b.brand
