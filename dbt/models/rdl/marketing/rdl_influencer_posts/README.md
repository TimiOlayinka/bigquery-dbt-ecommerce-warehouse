# rdl_influencer_posts

## Purpose
Deduplicated Raw Data Layer (RDL) staging model over `rdl_marketing.influencers_history` across all 7 OmniStyle Commerce Group brands.

## Grain
One row per `(post_id, brand)` ordered by latest `ingest_date`.

## Upstream inputs
- `source('rdl_marketing', 'influencers_history')`

## SLA
Daily by 07:00 Europe/London
