"""
Cloud Run Job: E-Commerce Orders Generator

Generates synthetic order + order_items data for all brands and uploads to GCS.
Replaces the AWS Lambda ecommerce_orders handler.

Usage:
    python -m ecommerce_orders.main
"""

import sys
import os

# Add the jobs root to sys.path so shared.* imports resolve
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timezone
from shared.config.ecommerce import BRAND_SOURCES
from shared.handler_logic import gen_orders
from shared import utils


def main():
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []

    for brand, cfg in BRAND_SOURCES.items():
        src = cfg["source"]
        n_c, n_p, n_o = cfg["customers_per"], cfg["products_per"], cfg["orders_per"]
        print(f"\n[{brand}] Generating orders...")
        orders, items = gen_orders(brand, src, n_o, n_c, n_p, ingest_date, ingest_time)
        keys.append(utils.upload(orders, brand, src, "orders", ingest_date))
        keys.append(utils.upload(items, brand, src, "order_items", ingest_date))

    print(f"\n✅ Done — {len(keys)} files uploaded.")


if __name__ == "__main__":
    main()
