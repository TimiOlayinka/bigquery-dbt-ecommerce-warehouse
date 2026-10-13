# rdl_email_campaigns

## Purpose
Deduplicated Raw Data Layer (RDL) staging model over `rdl_marketing.email_campaigns_history` across all 7 OmniStyle Commerce Group brands.

## Grain
One row per `(campaign_id, date_nk, brand)` ordered by latest `ingest_date`.

## Upstream inputs
- `source('rdl_marketing', 'email_campaigns_history')`

## SLA
Daily by 07:00 Europe/London
