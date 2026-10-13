# rdl_meta_ads

## Purpose
Deduplicated Raw Data Layer (RDL) staging model over `rdl_marketing.meta_ads_history` across all 7 Boohoo Group brands.

## Grain
One row per `(campaign_id, publisher_platform, date_nk, brand)` ordered by latest `ingest_date`.

## Upstream inputs
- `source('rdl_marketing', 'meta_ads_history')`

## SLA
Daily by 07:00 Europe/London
