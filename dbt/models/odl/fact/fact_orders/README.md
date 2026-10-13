# fact_orders

## Purpose
Unified order fact table with surrogate keys to dimensions

## Grain
One row per record in fact_orders

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| order_sk | varchar(200) | Surrogate key: MD5(order_id || brand) |
| order_nk | varchar(100) | Natural key from source system |
| customer_sk | varchar(200) | Surrogate key: MD5(customer_id || brand) |
| order_timestamp | date | Order timestamp |
| order_date | date | Order date |
| EXTRACT(YEAR | varchar | Extract(year |

## Key business rules
- Unifies 7 brand-level models via UNION ALL
- Surrogate keys generated via MD5(natural_key || '|' || brand)
- Filters to is_latest = TRUE from RDL (current-state only)

## Upstream inputs
- `ref('velvet_lane_orders')`
- `ref('velvet_mens_orders')`
- `ref('trend_pulse_orders')`
- `ref('rebel_chic_orders')`
- `ref('atelier_luxe_orders')`
- `ref('riviera_mode_orders')`
- `ref('grand_heritage_orders')`

## Downstream usage
- See lineage map

## SLA
Daily by 07:00 Europe/London

## Criticality
High
