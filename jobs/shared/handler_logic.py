"""
Data Generation Logic for E-Commerce Cloud Run Jobs

Generates realistic fake data for customers, orders, and products
using the field schemas defined in shared.config.ecommerce.
Uses only Python stdlib (random, uuid, datetime) — no Faker dependency.
"""

import random
import uuid
import string
from datetime import datetime, timedelta, timezone

from shared.config.ecommerce import (
    CUSTOMER_SCHEMAS,
    ORDER_SCHEMAS,
    PRODUCT_SCHEMAS,
    CATEGORIES,
    COLOURS,
    MATERIALS,
    SIZES_NUMERIC,
    SIZES_ALPHA,
    SIZES_SHOES,
    FIRST_F,
    FIRST_M,
    LAST_NAMES,
    CITIES,
    STATUSES_MAP,
    PAYMENTS_MAP,
)

# ──────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────

def _rand_id(prefix: str = "", length: int = 8) -> str:
    """Generate a random alphanumeric ID with optional prefix."""
    chars = string.ascii_uppercase + string.digits
    body = "".join(random.choices(chars, k=length))
    return f"{prefix}{body}" if prefix else body


def _rand_phone() -> str:
    return f"+44{''.join(random.choices(string.digits, k=10))}"


def _rand_email(first: str, last: str) -> str:
    domains = ["gmail.com", "yahoo.co.uk", "hotmail.com", "outlook.com", "icloud.com"]
    sep = random.choice([".", "_", ""])
    num = random.randint(1, 999)
    return f"{first.lower()}{sep}{last.lower()}{num}@{random.choice(domains)}"


def _rand_date(start_year: int = 2020, end_year: int = 2025) -> str:
    """Return a random ISO date between start_year and end_year."""
    start = datetime(start_year, 1, 1, tzinfo=timezone.utc)
    end = datetime(end_year, 12, 31, tzinfo=timezone.utc)
    delta = (end - start).days
    d = start + timedelta(days=random.randint(0, delta))
    return d.strftime("%Y-%m-%d")


def _rand_datetime_iso(start_year: int = 2020, end_year: int = 2025) -> str:
    start = datetime(start_year, 1, 1, tzinfo=timezone.utc)
    end = datetime(end_year, 12, 31, tzinfo=timezone.utc)
    delta = int((end - start).total_seconds())
    dt = start + timedelta(seconds=random.randint(0, delta))
    return dt.isoformat()


def _rand_price(low: float = 5.0, high: float = 150.0) -> float:
    return round(random.uniform(low, high), 2)


def _pick_size(category: str) -> str:
    if category == "Shoes":
        return random.choice(SIZES_SHOES)
    return random.choice(SIZES_NUMERIC + SIZES_ALPHA)


def _extra_value(field_name: str, brand: str, source: str) -> object:
    """Generate a plausible value for a source-specific extra field."""
    name_lower = field_name.lower()

    # Phone variants
    if "phone" in name_lower or "telephone" in name_lower:
        return _rand_phone()

    # City / Country
    if name_lower in ("city",):
        city, _ = random.choice(CITIES)
        return city
    if name_lower in ("country", "country_code", "country_id"):
        _, country = random.choice(CITIES)
        return country

    # Gender
    if "gender" in name_lower:
        return random.choice(["male", "female", "non_binary", "prefer_not_to_say"])

    # Subscription / opt-in / marketing booleans
    if any(kw in name_lower for kw in ("subscribed", "opt_in", "marketing", "receive_email")):
        return random.choice([True, False])

    # Segment / group / tags
    if any(kw in name_lower for kw in ("segment", "group", "tags")):
        segments = ["vip", "regular", "new", "lapsed", "high_value", "wholesale"]
        return random.choice(segments)

    # Date fields
    if any(kw in name_lower for kw in ("date", "created_at", "signup")):
        return _rand_date()

    # Orders count
    if "orders_count" in name_lower:
        return random.randint(0, 120)

    # Weight
    if "weight" in name_lower:
        return round(random.uniform(0.1, 5.0), 2)

    # Material / fabric
    if any(kw in name_lower for kw in ("material", "fabric")):
        return random.choice(MATERIALS)

    # Season
    if "season" in name_lower:
        return random.choice(["SS24", "AW24", "SS25", "AW25", "SS26"])

    # Supplier / vendor
    if any(kw in name_lower for kw in ("supplier", "vendor")):
        return _rand_id("SUP-", 6)

    # Inventory
    if "inventory" in name_lower:
        return random.randint(0, 5000)

    # Promo / coupon / discount
    if any(kw in name_lower for kw in ("promo", "coupon", "discount")):
        if random.random() < 0.3:
            return random.choice(["SAVE10", "WELCOME20", "FLASH15", "VIP25", "FREESHIP"])
        return None

    # Delivery / shipment / shipping / fulfillment
    if any(kw in name_lower for kw in ("delivery", "shipment", "shipping", "fulfillment")):
        return random.choice(["standard", "express", "next_day", "click_collect"])

    # Warehouse / store / site
    if any(kw in name_lower for kw in ("warehouse", "store", "site")):
        return _rand_id("WH-", 4)

    # Manufacturer
    if "manufacturer" in name_lower:
        return random.choice(["TextileCo", "FashionMfg", "ApparelGroup", "GarmentWorks", "StitchCraft"])

    # Fallback: short random string
    return _rand_id("", 6)


# ──────────────────────────────────────────────────────────────────
# Customer Generator
# ──────────────────────────────────────────────────────────────────

def gen_customers(brand: str, source: str, count: int,
                  ingest_date: str, ingest_time: str) -> list[dict]:
    """Generate *count* customer records using the schema for *source*."""
    schema = CUSTOMER_SCHEMAS[source]
    customers = []

    for i in range(count):
        gender = random.choice(["female", "male"])
        first = random.choice(FIRST_F if gender == "female" else FIRST_M)
        last = random.choice(LAST_NAMES)

        record = {
            schema["id_field"]: _rand_id("CUS-", 10),
            schema["email_field"]: _rand_email(first, last),
            schema["first_field"]: first,
            schema["last_field"]: last,
            "brand": brand,
            "source_system": source,
            "_ingest_date": ingest_date,
            "_ingest_time": ingest_time,
        }

        for ef in schema["extra_fields"]:
            record[ef] = _extra_value(ef, brand, source)

        customers.append(record)

    return customers


# ──────────────────────────────────────────────────────────────────
# Order Generator
# ──────────────────────────────────────────────────────────────────

def gen_orders(brand: str, source: str, n_orders: int,
               n_customers: int, n_products: int,
               ingest_date: str, ingest_time: str) -> tuple[list[dict], list[dict]]:
    """
    Generate *n_orders* order records and their line items.

    Returns:
        (orders, order_items) — two lists of dicts.
    """
    schema = ORDER_SCHEMAS[source]
    statuses = STATUSES_MAP[source]
    payments = PAYMENTS_MAP[source]

    orders = []
    items = []

    for _ in range(n_orders):
        order_id = _rand_id("ORD-", 10)
        customer_id = _rand_id("CUS-", 10)
        n_lines = random.randint(1, 5)
        line_total = 0.0

        for line in range(n_lines):
            qty = random.randint(1, 3)
            unit_price = _rand_price(8.0, 120.0)
            line_amount = round(qty * unit_price, 2)
            line_total += line_amount

            items.append({
                "order_id": order_id,
                "line_number": line + 1,
                "product_id": _rand_id("PRD-", 10),
                "quantity": qty,
                "unit_price": unit_price,
                "line_total": line_amount,
                "brand": brand,
                "source_system": source,
                "_ingest_date": ingest_date,
                "_ingest_time": ingest_time,
            })

        record = {
            schema["id_field"]: order_id,
            schema["cust_field"]: customer_id,
            schema["date_field"]: _rand_datetime_iso(),
            schema["total_field"]: round(line_total, 2),
            schema["status_field"]: random.choice(statuses),
            schema["payment_field"]: random.choice(payments),
            "brand": brand,
            "source_system": source,
            "_ingest_date": ingest_date,
            "_ingest_time": ingest_time,
        }

        for ef in schema["extra_fields"]:
            record[ef] = _extra_value(ef, brand, source)

        orders.append(record)

    return orders, items


# ──────────────────────────────────────────────────────────────────
# Product Generator
# ──────────────────────────────────────────────────────────────────

def gen_products(brand: str, source: str, count: int,
                 ingest_date: str, ingest_time: str) -> list[dict]:
    """Generate *count* product records using the schema for *source*."""
    schema = PRODUCT_SCHEMAS[source]
    products = []
    cat_keys = list(CATEGORIES.keys())

    for _ in range(count):
        cat = random.choice(cat_keys)
        subcat = random.choice(CATEGORIES[cat])
        colour = random.choice(COLOURS)
        price = _rand_price(5.0, 150.0)
        cost = round(price * random.uniform(0.25, 0.55), 2)
        name = f"{colour} {subcat}"

        record = {
            schema["id_field"]: _rand_id("PRD-", 10),
            schema["name_field"]: name,
            schema["color_field"]: colour,
            schema["size_field"]: _pick_size(cat),
            schema["price_field"]: price,
            schema["cost_field"]: cost,
            schema["cat_field"]: cat,
            schema["subcat_field"]: subcat,
            "brand": brand,
            "source_system": source,
            "_ingest_date": ingest_date,
            "_ingest_time": ingest_time,
        }

        for ef in schema["extra_fields"]:
            record[ef] = _extra_value(ef, brand, source)

        products.append(record)

    return products
