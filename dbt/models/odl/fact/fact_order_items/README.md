# fact_order_items

## Purpose
Granular order line-item fact table unifying SKU-level transactions across all 7 Boohoo Group brands (`Boohoo`, `Boohoo Man`, `PrettyLittleThing`, `NastyGal`, `Karen Millen`, `Coast`, `Debenhams`).

## Grain
One row per order line item (`order_item_sk`)

## BigQuery FinOps Architecture
- **Materialization**: `incremental` (`incremental_strategy = "merge"`, `unique_key = "order_item_sk"`)
- **Partitioning**: Time-unit daily partitioning on `order_date` (`DAY`) with `require_partition_filter = true`
- **Clustering**: Multi-column clustering on `["brand", "product_sk", "order_sk"]` to co-locate brand and SKU blocks

## Table structure
| Column | Type | Description |
|--------|------|-------------|
| order_item_sk | string | Surrogate key: `TO_HEX(MD5(order_item_id \|\| '\|' \|\| brand))` |
| order_item_nk | string | Natural line-item key from source platform |
| order_sk | string | Foreign key to `odl.fact_orders` |
| product_sk | string | Foreign key to `odl.dim_products` |
| customer_sk | string | Foreign key to `odl.dim_customers` |
| order_date | date | Partition key (`YYYY-MM-DD`) |
| quantity | int64 | Units purchased on line item |
| unit_price | numeric | Unit selling price (GBP) |
| item_discount_amount | numeric | Line-level promotional discount (GBP) |
| gross_item_revenue | numeric | `quantity * unit_price` |
| net_item_revenue | numeric | `(quantity * unit_price) - item_discount_amount` |
| brand | string | Boohoo Group brand name |
| source_system | string | E-commerce platform identifier |

## SLA
Daily by 07:00 Europe/London
