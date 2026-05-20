FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY shared/ ./shared/
COPY ecommerce_customers/ ./ecommerce_customers/
COPY ecommerce_orders/ ./ecommerce_orders/
COPY ecommerce_products/ ./ecommerce_products/

# Default: run customers job. Override with --command flag in Cloud Run
CMD ["python", "-m", "ecommerce_customers.main"]
