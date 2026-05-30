"""
Cloud Run Job: Marketing Google Ads
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timezone
from shared.marketing_logic import gen_google_ads
from shared import utils

BRANDS = ["boohoo", "boohoo_man", "prettylittlething", "nastygal", "karen_millen", "coast", "debenhams"]

def main():
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []

    for brand in BRANDS:
        print(f"\n[{brand}] Generating Google Ads...")
        data = gen_google_ads(brand, 50, ingest_date, ingest_time)
        keys.append(utils.upload(data, brand, "google_ads", ingest_date))

    print(f"\n✅ Done — {len(keys)} files uploaded.")

if __name__ == "__main__":
    main()
