"""
Build & Push Docker Images for Cloud Run Jobs

Replaces build_zips.py (Lambda ZIP packager).
Builds a single multi-job Docker image and pushes it to Artifact Registry.
Each Cloud Run Job overrides CMD to select its entrypoint module.

Usage:
    python scripts/build_images.py
    python scripts/build_images.py --push          # also push to AR
    python scripts/build_images.py --tag v1.2.3    # custom tag
"""

import os
import sys
import argparse
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
JOBS_DIR = os.path.join(SCRIPT_DIR, "..", "jobs")

# Artifact Registry defaults — override via env vars
AR_REGION = os.environ.get("AR_REGION", "europe-west2")
AR_PROJECT = os.environ.get("GCP_PROJECT_ID", "bellosdata")
AR_REPO = os.environ.get("AR_REPO", "omnistyle-jobs")

# The 9 Cloud Run Jobs
JOBS_LIST = [
    "ecommerce_customers",
    "ecommerce_orders",
    "ecommerce_products",
    "marketing_meta_ads",
    "marketing_google_ads",
    "marketing_tiktok_ads",
    "marketing_ga4_sessions",
    "marketing_email_campaigns",
    "marketing_influencers",
]


def _run(cmd: list[str], **kwargs) -> None:
    """Run a subprocess, printing the command and raising on failure."""
    print(f"  $ {' '.join(cmd)}")
    subprocess.run(cmd, check=True, **kwargs)


def build_image(tag: str) -> None:
    """Build the Docker image from jobs/ and tag it for all jobs."""
    # Build a single base image first
    print("\n🔨 Building base image")
    _run(["docker", "build", "-t", "omnistyle-base", JOBS_DIR])

    print("\n🏷️ Tagging image for all jobs")
    for job in JOBS_LIST:
        image_uri = f"{AR_REGION}-docker.pkg.dev/{AR_PROJECT}/{AR_REPO}/{job}:{tag}"
        _run(["docker", "tag", "omnistyle-base", image_uri])
        _run(["docker", "tag", "omnistyle-base", f"{AR_REGION}-docker.pkg.dev/{AR_PROJECT}/{AR_REPO}/{job}:latest"])


def push_image(tag: str) -> None:
    """Push the images (and :latest) to Artifact Registry."""
    for job in JOBS_LIST:
        image_uri = f"{AR_REGION}-docker.pkg.dev/{AR_PROJECT}/{AR_REPO}/{job}:{tag}"
        latest_uri = f"{AR_REGION}-docker.pkg.dev/{AR_PROJECT}/{AR_REPO}/{job}:latest"
        print(f"\n🚀 Pushing image: {image_uri}")
        _run(["docker", "push", image_uri])
        print(f"🚀 Pushing image: {latest_uri}")
        _run(["docker", "push", latest_uri])


def main():
    parser = argparse.ArgumentParser(description="Build Cloud Run Job Docker images")
    parser.add_argument("--tag", default="latest", help="Image tag (default: latest)")
    parser.add_argument("--push", action="store_true", help="Push to Artifact Registry after build")
    args = parser.parse_args()

    # Verify jobs directory exists
    if not os.path.isdir(JOBS_DIR):
        print(f"❌ Jobs directory not found: {JOBS_DIR}")
        sys.exit(1)

    # Verify Dockerfile exists
    dockerfile = os.path.join(JOBS_DIR, "Dockerfile")
    if not os.path.isfile(dockerfile):
        print(f"❌ Dockerfile not found: {dockerfile}")
        sys.exit(1)

    build_image(args.tag)

    if args.push:
        push_image(args.tag)

    print(f"\n✅ Build complete.")


if __name__ == "__main__":
    main()
