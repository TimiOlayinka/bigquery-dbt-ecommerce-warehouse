"""
Cloud Run Job: E-Commerce Customers Generator

Generates synthetic customer data for all brands and uploads to GCS as JSONL.GZ.
Replaces the AWS Lambda ecommerce_customers handler.

Usage:
    python -m ecommerce_customers.main
"""

import sys
import os

# Add the jobs root to sys.path so shared.* imports resolve
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timezone
from shared.config.ecommerce import BRAND_SOURCES
from shared.handler_logic import gen_customers
from shared import utils


def main():
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []

    for brand, cfg in BRAND_SOURCES.items():
        src = cfg["source"]
        n_c = cfg["customers_per"]
        print(f"\n[{brand}] Generating customers...")
        customers = gen_customers(brand, src, n_c, ingest_date, ingest_time)
        keys.append(utils.upload(customers, brand, "customers", ingest_date))

    print(f"\n✅ Done — {len(keys)} files uploaded.")


if __name__ == "__main__":
    main()
