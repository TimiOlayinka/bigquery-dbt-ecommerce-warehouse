"""
Cloud Run Job: Marketing Influencers
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timezone
from shared.marketing_logic import gen_influencers
from shared import utils

BRANDS = ["velvet_lane", "velvet_mens", "trend_pulse", "rebel_chic", "atelier_luxe", "riviera_mode", "grand_heritage"]

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
