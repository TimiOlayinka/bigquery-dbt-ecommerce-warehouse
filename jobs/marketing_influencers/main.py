"""
Cloud Run Job: Marketing Influencers
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timezone
from shared.marketing_logic import gen_influencers
from shared import utils

BRANDS = ["boohoo", "boohoo_man", "prettylittlething", "nastygal", "karen_millen", "coast", "debenhams"]

def main():
    now = datetime.now(timezone.utc)
    ingest_date = now.strftime("%Y-%m-%d")
    ingest_time = now.isoformat()
    keys = []

    for brand in BRANDS:
        print(f"\n[{brand}] Generating Influencer Data...")
        data = gen_influencers(brand, 20, ingest_date, ingest_time)
        keys.append(utils.upload(data, brand, "influencers", ingest_date))

    print(f"\n✅ Done — {len(keys)} files uploaded.")

if __name__ == "__main__":
    main()
