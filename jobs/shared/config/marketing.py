"""
Marketing Data Configuration and Schemas
"""

MARKETING_CHANNELS = [
    "meta_ads",
    "google_ads",
    "tiktok_ads",
    "ga4_sessions",
    "email_campaigns",
    "influencers"
]

# Common dimensions to randomize
CAMPAIGN_NAMES = [
    "Summer_Sale_2024", "Black_Friday_Early_Access", "New_Arrivals_Spring",
    "Clearance_Blast", "VIP_Exclusive_Promo", "Holiday_Gift_Guide",
    "Back_To_School", "Valentine_Specials", "Flash_Sale_48H", "Welcome_Series"
]

DEVICE_CATEGORIES = ["mobile", "desktop", "tablet"]
TRAFFIC_SOURCES = ["google", "direct", "facebook", "instagram", "tiktok", "email", "bing", "criteo"]
TRAFFIC_MEDIUMS = ["cpc", "organic", "social", "email", "referral", "display"]
INFLUENCER_PLATFORMS = ["instagram", "tiktok", "youtube"]
POST_TYPES = ["reel", "story", "post", "video", "short"]

# We define the expected schema/fields for each channel. 
# The generator logic will build dictionaries matching these keys.
