# dim_customers

## Purpose
Unified customer dimension across all OmniStyle Commerce Group brands (star schema)

## Grain
One row per (email) per brand

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| customer_sk | varchar(200) | Surrogate key: MD5(customer_id || brand) |
| customer_nk | varchar(100) | Natural key from source system |
| email | varchar | Email |
| first_name | varchar | First name |
| last_name | varchar | Last name |
| phone | varchar | Phone |
| city | varchar | City |
| country | varchar | Country |
| customer_segment | varchar | Customer segment |
| registration_date | date | Registration date |
| gender | varchar | Gender |
| is_marketing_opted_in | boolean | Boolean: marketing opted in |
| brand | varchar | OmniStyle Commerce Group brand name |
| source_system | varchar | Source platform identifier |
| ingest_date | date | Date this version was loaded from source |
| dwh_created_at | varchar | Timestamp when this row was created in the warehouse |

## Key business rules
- Deduplicated by (email), keeping latest version
- Unifies 7 brand-level models via UNION ALL
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Filters to is_latest = TRUE from RDL (current-state only)

## Upstream inputs
- `ref('velvet_lane_customers')`
- `ref('velvet_mens_customers')`
- `ref('trend_pulse_customers')`
- `ref('rebel_chic_customers')`
- `ref('atelier_luxe_customers')`
- `ref('riviera_mode_customers')`
- `ref('grand_heritage_customers')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
