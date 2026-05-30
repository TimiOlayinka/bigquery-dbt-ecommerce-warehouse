"""
Cloud Run Job: E-Commerce Products Generator

Generates synthetic product data for all brands and uploads to GCS as JSONL.GZ.
Replaces the AWS Lambda ecommerce_products handler.

Usage:
    python -m ecommerce_products.main
"""

import sys
import os

# Add the jobs root to sys.path so shared.* imports resolve
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timezone
from shared.config.ecommerce import BRAND_SOURCES
from shared.handler_logic import gen_products
from shared import utils


def main():
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []

    for brand, cfg in BRAND_SOURCES.items():
        src = cfg["source"]
        n_p = cfg["products_per"]
        print(f"\n[{brand}] Generating products...")
        products = gen_products(brand, src, n_p, ingest_date, ingest_time)
        keys.append(utils.upload(products, brand, "products", ingest_date))

    print(f"\n✅ Done — {len(keys)} files uploaded.")


if __name__ == "__main__":
    main()
