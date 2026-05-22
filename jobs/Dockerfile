FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY shared/ ./shared/
COPY ecommerce_customers/ ./ecommerce_customers/
COPY ecommerce_orders/ ./ecommerce_orders/
COPY ecommerce_products/ ./ecommerce_products/

COPY marketing_meta_ads/ ./marketing_meta_ads/
COPY marketing_google_ads/ ./marketing_google_ads/
COPY marketing_tiktok_ads/ ./marketing_tiktok_ads/
COPY marketing_ga4_sessions/ ./marketing_ga4_sessions/
COPY marketing_email_campaigns/ ./marketing_email_campaigns/
COPY marketing_influencers/ ./marketing_influencers/

# Default: run customers job. Override with --command flag in Cloud Run
CMD ["python", "-m", "ecommerce_customers.main"]
