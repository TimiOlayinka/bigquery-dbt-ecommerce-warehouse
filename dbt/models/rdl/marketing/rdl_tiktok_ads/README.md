# rdl_tiktok_ads

## Purpose
Deduplicated Raw Data Layer (RDL) staging model over `rdl_marketing.tiktok_ads_history` across all 7 OmniStyle Commerce Group brands.

## Grain
One row per `(ad_id, date_nk, brand)` ordered by latest `ingest_date`.

## Upstream inputs
- `source('rdl_marketing', 'tiktok_ads_history')`

## SLA
Daily by 07:00 Europe/London
