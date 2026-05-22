"""
Data Generation Logic for Marketing Cloud Run Jobs
Generates synthetic data for 6 marketing channels.
"""

import random
from typing import List, Dict
from shared.config.marketing import (
    CAMPAIGN_NAMES,
    DEVICE_CATEGORIES,
    TRAFFIC_SOURCES,
    TRAFFIC_MEDIUMS,
    INFLUENCER_PLATFORMS,
    POST_TYPES
)

def _rand_id(prefix: str, length: int = 8) -> str:
    import string
    chars = string.ascii_uppercase + string.digits
    body = "".join(random.choices(chars, k=length))
    return f"{prefix}{body}"

def _rand_ip() -> str:
    return f"{random.randint(1,255)}.{random.randint(0,255)}.{random.randint(0,255)}.{random.randint(1,255)}"

def gen_meta_ads(brand: str, count: int, ingest_date: str, ingest_time: str) -> List[Dict]:
    records = []
    for _ in range(count):
        spend = round(random.uniform(50.0, 5000.0), 2)
        roas = round(random.uniform(0.5, 6.0), 2)
        revenue = round(spend * roas, 2)
        impressions = int(spend * random.uniform(50, 200))
        clicks = int(impressions * random.uniform(0.01, 0.05))
        purchases = int(clicks * random.uniform(0.02, 0.10))

        records.append({
            "ad_id": _rand_id("FB-AD-"),
            "campaign_id": _rand_id("FB-CMP-"),
            "campaign_name": random.choice(CAMPAIGN_NAMES),
            "impressions": impressions,
            "clicks": clicks,
            "spend": spend,
            "purchases": purchases,
            "revenue": revenue,
            "roas": roas,
            "brand": brand,
            "_ingest_date": ingest_date,
            "_ingest_time": ingest_time
        })
    return records

def gen_google_ads(brand: str, count: int, ingest_date: str, ingest_time: str) -> List[Dict]:
    records = []
    for _ in range(count):
        cost = round(random.uniform(10.0, 3000.0), 2)
        roas = round(random.uniform(0.8, 8.0), 2)
        revenue = round(cost * roas, 2)
        impressions = int(cost * random.uniform(10, 80))
        clicks = int(impressions * random.uniform(0.05, 0.15))
        conversions = int(clicks * random.uniform(0.05, 0.20))

        records.append({
            "ad_group_id": _rand_id("GOOG-AG-"),
            "campaign_name": random.choice(CAMPAIGN_NAMES),
            "keyword": random.choice(["dresses", "menswear", "shoes sale", "summer tops", "party outfit"]),
            "impressions": impressions,
            "clicks": clicks,
            "cost": cost,
            "conversions": conversions,
            "revenue": revenue,
            "roas": roas,
            "brand": brand,
            "_ingest_date": ingest_date,
            "_ingest_time": ingest_time
        })
    return records

def gen_tiktok_ads(brand: str, count: int, ingest_date: str, ingest_time: str) -> List[Dict]:
    records = []
    for _ in range(count):
        spend = round(random.uniform(20.0, 4000.0), 2)
        roas = round(random.uniform(0.3, 4.0), 2)
        revenue = round(spend * roas, 2)
        views = int(spend * random.uniform(200, 1000))
        likes = int(views * random.uniform(0.05, 0.20))
        shares = int(likes * random.uniform(0.01, 0.10))
        clicks = int(views * random.uniform(0.01, 0.04))

        records.append({
            "video_id": _rand_id("TT-VID-"),
            "campaign_name": random.choice(CAMPAIGN_NAMES),
            "views": views,
            "likes": likes,
            "shares": shares,
            "clicks": clicks,
            "spend": spend,
            "revenue": revenue,
            "roas": roas,
            "brand": brand,
            "_ingest_date": ingest_date,
            "_ingest_time": ingest_time
        })
    return records

def gen_ga4_sessions(brand: str, count: int, ingest_date: str, ingest_time: str) -> List[Dict]:
    records = []
    for _ in range(count):
        session_duration = random.randint(0, 1200) # seconds
        bounced = session_duration < 10

        records.append({
            "session_id": _rand_id("GA-SESS-", 12),
            "client_id": _rand_id("CLIENT-", 10),
            "source": random.choice(TRAFFIC_SOURCES),
            "medium": random.choice(TRAFFIC_MEDIUMS),
            "campaign": random.choice(CAMPAIGN_NAMES + ["(none)", "(not set)"]),
            "pageviews": random.randint(1, 25) if not bounced else 1,
            "session_duration": session_duration,
            "bounced": bounced,
            "device_category": random.choice(DEVICE_CATEGORIES),
            "ip_address": _rand_ip(),
            "brand": brand,
            "_ingest_date": ingest_date,
            "_ingest_time": ingest_time
        })
    return records

def gen_email_campaigns(brand: str, count: int, ingest_date: str, ingest_time: str) -> List[Dict]:
    records = []
    for _ in range(count):
        sent = random.randint(10000, 500000)
        opened = int(sent * random.uniform(0.15, 0.40))
        clicked = int(opened * random.uniform(0.05, 0.15))
        bounced = int(sent * random.uniform(0.001, 0.02))
        unsubscribed = int(sent * random.uniform(0.001, 0.01))
        revenue_generated = round(clicked * random.uniform(0.5, 5.0), 2)

        records.append({
            "campaign_id": _rand_id("EML-"),
            "campaign_name": random.choice(CAMPAIGN_NAMES),
            "sent": sent,
            "opened": opened,
            "clicked": clicked,
            "bounced": bounced,
            "unsubscribed": unsubscribed,
            "revenue_generated": revenue_generated,
            "brand": brand,
            "_ingest_date": ingest_date,
            "_ingest_time": ingest_time
        })
    return records

def gen_influencers(brand: str, count: int, ingest_date: str, ingest_time: str) -> List[Dict]:
    records = []
    for _ in range(count):
        reach = random.randint(5000, 2000000)
        likes = int(reach * random.uniform(0.02, 0.15))
        comments = int(likes * random.uniform(0.01, 0.05))
        promo_code_uses = int(reach * random.uniform(0.0001, 0.005))
        revenue_generated = round(promo_code_uses * random.uniform(20.0, 100.0), 2)

        records.append({
            "post_id": _rand_id("INF-POST-"),
            "influencer_handle": f"@creator_{_rand_id('', 4).lower()}",
            "platform": random.choice(INFLUENCER_PLATFORMS),
            "post_type": random.choice(POST_TYPES),
            "likes": likes,
            "comments": comments,
            "reach": reach,
            "promo_code_uses": promo_code_uses,
            "revenue_generated": revenue_generated,
            "brand": brand,
            "_ingest_date": ingest_date,
            "_ingest_time": ingest_time
        })
    return records
