# Runbook: fact_order_items

## What this model supports
SKU-level product performance (`bi.fact_product_performance`), basket size analytics, and gross/net item margin reporting across all 7 brands.

## Expected refresh
Daily at 02:00 UTC via Airflow / Cloud Run incremental dbt build (`dbt build --select fact_order_items+`).

## Failure impact
Downstream `bi.fact_product_performance` will serve stale SKU sales metrics; Looker Studio merchandising dashboards will lag by 1 day.

## Diagnostics
```sql
-- Verify latest partitions per brand (partition filter required)
SELECT
    brand,
    order_date,
    COUNT(*) AS line_items,
    SUM(net_item_revenue) AS net_revenue
FROM `bellosdata.odl.fact_order_items`
WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY 1, 2
ORDER BY 2 DESC, 1;
```

## Recovery steps
1. For incremental repair of the last 3 days: `dbt run --select fact_order_items`
2. For full historical backfill: `dbt run --select fact_order_items --full-refresh`

## Escalation
data-team@omnistyle-commerce.co.uk
