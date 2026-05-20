------------------------------------------------------------------------------------------------------------------------
-- odl.dim_time
-- Conformed date dimension
------------------------------------------------------------------------------------------------------------------------
WITH date_spine AS (
    SELECT date_day
    FROM UNNEST(GENERATE_DATE_ARRAY('2024-01-01', CURRENT_DATE() + 365)) AS date_day
)
SELECT
    date_day                                    AS date_day,
    EXTRACT(DAYOFWEEK FROM date_day)                 AS day_of_week,
    FORMAT_DATE('%A', date_day)                   AS day_name,
    EXTRACT(DAY FROM date_day)                 AS day_of_month,
    EXTRACT(MONTH FROM date_day)               AS month_number,
    FORMAT_DATE('%B', date_day)                 AS month_name,
    EXTRACT(QUARTER FROM date_day)             AS quarter,
    EXTRACT(YEAR FROM date_day)                AS year,
    FORMAT_DATE('%G-%V', date_day)              AS iso_week,
    CASE WHEN EXTRACT(DAYOFWEEK FROM date_day) IN (1,7) THEN TRUE ELSE FALSE END AS is_weekend,
    CASE WHEN EXTRACT(MONTH FROM date_day) IN (11,12,1) THEN TRUE ELSE FALSE END AS is_peak_season
FROM date_spine
