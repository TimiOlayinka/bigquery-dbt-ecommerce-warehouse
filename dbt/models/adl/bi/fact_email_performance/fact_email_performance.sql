{{
    config(
        materialized = "table",
        partition_by = {"field": "date_nk", "data_type": "date", "granularity": "day"},
        cluster_by = ["brand"],
        tags = ["adl", "bi", "finops_partitioned"]
    )
}}

------------------------------------------------------------------------------------------------------------------------
-- bi.fact_email_performance
-- Email/CRM marketing dashboard — campaign type performance and health metrics
-- Feeds the email marketing executive report
------------------------------------------------------------------------------------------------------------------------
SELECT
    date_nk,
    EXTRACT(YEAR FROM date_nk)                          AS year,
    EXTRACT(MONTH FROM date_nk)                         AS month,
    brand,
    brand_tier,
    campaign_type,
    campaign_name,
    subject_line,
    -- Volume metrics
    list_size,
    delivered,
    opened,
    unique_opens,
    clicked,
    unique_clicks,
    unsubscribed,
    bounced,
    spam_complaints,
    converted,
    revenue,
    -- Rate metrics
    delivery_rate,
    open_rate,
    click_rate,
    click_to_open_rate,
    conversion_rate,
    revenue_per_email,
    -- Derived health metrics
    ROUND(CAST(unsubscribed AS FLOAT64) / NULLIF(delivered, 0) * 100, 4) AS unsubscribe_rate,
    ROUND(CAST(bounced AS FLOAT64) / NULLIF(list_size, 0) * 100, 4)     AS bounce_rate,
    ROUND(CAST(spam_complaints AS FLOAT64) / NULLIF(delivered, 0) * 100, 4) AS spam_rate,
    -- Revenue attribution
    ROUND(revenue / NULLIF(converted, 0), 2)            AS avg_order_value,
    ROUND(revenue / NULLIF(clicked, 0), 2)              AS revenue_per_click
FROM {{ ref('fact_email_engagement') }}
