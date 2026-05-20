"""
GCP Session Helper — Cloud-Compatible Authentication

Provides a unified credential factory that works both:
  1. Locally (Application Default Credentials via gcloud auth)
  2. Cloud (Service Account key JSON mounted by docker-compose)

Usage:
    from gcp_session import get_gcp_credentials, GCP_PROJECT_ID
    credentials = get_gcp_credentials()

Author: Antigravity (DATA-29)
"""

import os
import logging

import google.auth
from google.auth import credentials as ga_credentials
from google.oauth2 import service_account

logger = logging.getLogger(__name__)

GCP_PROJECT_ID = os.environ.get("GCP_PROJECT_ID", "bellosdata")
GCP_REGION = os.environ.get("GCP_REGION", "europe-west2")


def get_gcp_credentials() -> ga_credentials.Credentials:
    """
    Create GCP credentials using the best available method.

    Priority:
    1. Service account key file (GOOGLE_APPLICATION_CREDENTIALS) — cloud instances
    2. Application Default Credentials (ADC) — local dev with gcloud auth
    """
    sa_key_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")

    # Cloud: explicit service account key file
    if sa_key_path and os.path.isfile(sa_key_path):
        logger.debug("Using service account key: %s (cloud mode)", sa_key_path)
        credentials = service_account.Credentials.from_service_account_file(
            sa_key_path,
            scopes=["https://www.googleapis.com/auth/cloud-platform"],
        )
        return credentials

    # Local: Application Default Credentials (gcloud auth application-default login)
    try:
        credentials, project = google.auth.default(
            scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )
        logger.debug("Using Application Default Credentials (local mode), project=%s", project)
        return credentials
    except google.auth.exceptions.DefaultCredentialsError:
        pass

    raise RuntimeError(
        "No GCP credentials found. Either set GOOGLE_APPLICATION_CREDENTIALS "
        "to a service account key JSON path, or run: "
        "gcloud auth application-default login"
    )


def is_cloud() -> bool:
    """Check if running in cloud mode (service account present, no local drives)."""
    return bool(os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")) or not os.path.exists("D:\\")
