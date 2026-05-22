"""
GCS Upload Utility for Cloud Run Jobs

Compresses records to JSONL.GZ and uploads to Google Cloud Storage.
Replaces the old Lambda/S3-based upload logic.
"""

import gzip
import json
import os
from google.cloud import storage

GCS_BUCKET = os.environ.get("GCS_BUCKET", "boohoo-rdl-staging-bellosdata")


def upload(records: list[dict], brand: str, source: str, dataset: str, ingest_date: str) -> str:
    """
    Serialize records to JSONL, gzip-compress, and upload to GCS.

    Args:
        records:      List of dicts — one JSON object per line.
        brand:        Brand slug (e.g. "boohoo", "prettylittlething").
        source:       Source system (e.g. "boohoo_commerce", "shopify").
        dataset:      Dataset name (e.g. "customers", "orders").
        ingest_date:  ISO date string for partitioning (YYYY-MM-DD).

    Returns:
        The GCS object path that was written (gs://bucket/key).
    """
    # Build the GCS object key matching the old S3 layout:
    #   raw/{source}/{brand}/{dataset}/ingest_date={date}/{dataset}.jsonl.gz
    key = (
        f"raw/{source}/{brand}/{dataset}/"
        f"ingest_date={ingest_date}/{dataset}.jsonl.gz"
    )

    # Serialize to JSONL and gzip-compress in memory
    jsonl_bytes = "\n".join(json.dumps(r, default=str) for r in records).encode("utf-8")
    compressed = gzip.compress(jsonl_bytes)

    # Upload to GCS
    client = storage.Client()
    bucket = client.bucket(GCS_BUCKET)
    blob = bucket.blob(key)
    blob.upload_from_string(compressed, content_type="application/gzip")

    gcs_path = f"gs://{GCS_BUCKET}/{key}"
    print(f"  ✓ Uploaded {len(records):,} records → {gcs_path}")
    return gcs_path
