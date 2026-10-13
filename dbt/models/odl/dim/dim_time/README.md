# dim_time

## Purpose
Conformed calendar and fiscal date dimension generated via BigQuery `GENERATE_DATE_ARRAY` to provide standardized time attributes across all e-commerce and marketing fact tables.

## Grain
One row per calendar day (`date_day`)

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| date_day | date | Primary calendar date key (`YYYY-MM-DD`) |
| day_of_week | int64 | Day of week number (1=Sunday to 7=Saturday in BigQuery) |
| day_name | string | Full weekday name (e.g. Monday, Tuesday) |
| day_of_month | int64 | Day of the month (1–31) |
| month_number | int64 | Calendar month number (1–12) |
| month_name | string | Full month name (e.g. January, February) |
| quarter | int64 | Calendar quarter (1–4) |
| year | int64 | Four-digit calendar year |
| iso_week | string | ISO 8601 week identifier (`YYYY-WW`) |
| is_weekend | boolean | True if Saturday or Sunday |
| is_peak_season | boolean | True during retail peak trading months (Nov, Dec, Jan) |

## Key business rules
- Dynamically generates a continuous, gap-free date spine from `2024-01-01` through `CURRENT_DATE() + 365` using `UNNEST(GENERATE_DATE_ARRAY(...))`
- Flags retail peak trading months (`Nov`, `Dec`, `Jan`) via `is_peak_season` for Black Friday / Cyber Monday and January sales reporting
- Zero upstream table scans required (pure in-memory BigQuery array generation)

## Upstream inputs
- None (deterministic BigQuery date array spine)

## Downstream usage
- Joined by all ODL and ADL/BI fact tables (`fact_orders`, `fact_daily_sales`, `fact_campaign_performance`, `fact_ga4_sessions`) on `order_date` / `date_nk = date_day`

## SLA
Daily by 07:00 Europe/London

## Criticality
High
