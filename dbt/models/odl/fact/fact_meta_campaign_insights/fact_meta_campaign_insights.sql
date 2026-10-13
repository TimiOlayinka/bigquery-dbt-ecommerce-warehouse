{{
    config(
        materialized = "incremental",
        incremental_strategy = "merge",
        unique_key = "meta_insight_sk",
        partition_by = {
            "field": "date_nk",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by = ["brand", "publisher_platform", "campaign_sk"],
        require_partition_filter = true,
        labels = {
            "layer": "odl",
            "domain": "marketing",
            "finops_optimized": "true"
        }
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- odl.fact_meta_campaign_insights
-- Unified Meta Ads campaign insights with surrogate keys
-- BigQuery FinOps: Partitioned by date_nk (DAY), clustered by (brand, publisher_platform, campaign_sk),
-- incremental MERGE with require_partition_filter = true
------------------------------------------------------------------------------------------------------------------------
WITH raw_data AS (
    SELECT
        campaign_id                                     AS meta_campaign_nk,
        campaign_name                                   AS meta_campaign_name,
        objective,
        account_id                                      AS meta_account_nk,
        publisher_platform,
        CAST(date_nk AS DATE)                           AS date_nk,
        CAST(spend AS NUMERIC)                          AS spend,
        CAST(impressions AS INT64)                      AS impressions,
        CAST(clicks AS INT64)                           AS clicks,
        CAST(reach AS INT64)                            AS reach,
        CAST(frequency AS NUMERIC)                      AS frequency,
        CAST(cpc AS NUMERIC)                            AS cpc,
        CAST(cpm AS NUMERIC)                            AS cpm,
        CAST(ctr AS NUMERIC)                            AS ctr,
        CAST(outbound_clicks AS INT64)                  AS outbound_clicks,
        CAST(outbound_clicks_ctr AS NUMERIC)            AS outbound_clicks_ctr,
        CAST(video_p25_watched AS INT64)                AS video_p25_watched,
        CAST(video_p50_watched AS INT64)                AS video_p50_watched,
        CAST(video_p75_watched AS INT64)                AS video_p75_watched,
        CAST(video_p100_watched AS INT64)               AS video_p100_watched,
        brand,
        ingest_date
    FROM {{ ref('rdl_meta_ads') }}
    WHERE {{ enforce_partition_filter('CAST(date_nk AS DATE)') }}
)
SELECT
    TO_HEX(MD5(rd.meta_campaign_nk || '|' || CAST(rd.date_nk AS STRING) || '|' || rd.publisher_platform || '|' || rd.brand))
        AS meta_insight_sk,
    rd.meta_campaign_nk,
    rd.meta_campaign_name,
    dc.campaign_sk,
    dc.campaign_type,
    rd.objective,
    rd.publisher_platform,
    rd.date_nk,
    EXTRACT(YEAR FROM rd.date_nk)                       AS year,
    EXTRACT(MONTH FROM rd.date_nk)                      AS month,
    rd.spend,
    rd.impressions,
    rd.clicks,
    rd.reach,
    rd.frequency,
    rd.cpc,
    rd.cpm,
    rd.ctr,
    rd.outbound_clicks,
    rd.outbound_clicks_ctr,
    rd.video_p25_watched,
    rd.video_p50_watched,
    rd.video_p75_watched,
    rd.video_p100_watched,
    rd.brand,
    b.brand_tier,
    rd.ingest_date,
    CURRENT_TIMESTAMP()                                 AS dwh_created_at
FROM raw_data rd
LEFT JOIN {{ ref('dim_campaigns') }} dc
    ON rd.meta_campaign_nk = dc.campaign_nk AND dc.platform = 'Meta Ads' AND rd.brand = dc.brand
LEFT JOIN {{ ref('map_brand') }} b
    ON rd.brand = b.brand
