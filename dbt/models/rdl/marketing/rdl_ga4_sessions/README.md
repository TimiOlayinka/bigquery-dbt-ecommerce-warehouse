# rdl_ga4_sessions

## Purpose
Deduplicated Raw Data Layer (RDL) staging model over `rdl_marketing.ga4_sessions_history` across all 7 OmniStyle Commerce Group brands.

## Grain
One row per `(session_id, brand)` ordered by latest `ingest_date`.

## Upstream inputs
- `source('rdl_marketing', 'ga4_sessions_history')`

## SLA
Daily by 07:00 Europe/London
