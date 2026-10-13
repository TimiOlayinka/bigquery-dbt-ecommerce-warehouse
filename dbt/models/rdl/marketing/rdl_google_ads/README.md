# rdl_google_ads

## Purpose
Deduplicated Raw Data Layer (RDL) staging model over `rdl_marketing.google_ads_history` across all 7 Boohoo Group brands.

## Grain
One row per `(ad_id, date_nk, device, brand)` ordered by latest `ingest_date`.

## Upstream inputs
- `source('rdl_marketing', 'google_ads_history')`

## SLA
Daily by 07:00 Europe/London
