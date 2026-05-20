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
AR_REPO = os.environ.get("AR_REPO", "cloud-run-jobs")
IMAGE_NAME = "ecommerce-data-generator"

# The 3 Cloud Run Jobs and their CMD overrides
JOBS = {
    "ecommerce-customers": ["python", "-m", "ecommerce_customers.main"],
    "ecommerce-orders":    ["python", "-m", "ecommerce_orders.main"],
    "ecommerce-products":  ["python", "-m", "ecommerce_products.main"],
}


def _run(cmd: list[str], **kwargs) -> None:
    """Run a subprocess, printing the command and raising on failure."""
    print(f"  $ {' '.join(cmd)}")
    subprocess.run(cmd, check=True, **kwargs)


def build_image(tag: str) -> str:
    """Build the Docker image from jobs/ and return the full image URI."""
    image_uri = f"{AR_REGION}-docker.pkg.dev/{AR_PROJECT}/{AR_REPO}/{IMAGE_NAME}:{tag}"

    print(f"\n🔨 Building image: {image_uri}")
    _run([
        "docker", "build",
        "-t", image_uri,
        "-t", f"{AR_REGION}-docker.pkg.dev/{AR_PROJECT}/{AR_REPO}/{IMAGE_NAME}:latest",
        JOBS_DIR,
    ])

    return image_uri


def push_image(image_uri: str) -> None:
    """Push the image (and :latest) to Artifact Registry."""
    print(f"\n🚀 Pushing image: {image_uri}")
    _run(["docker", "push", image_uri])

    latest_uri = image_uri.rsplit(":", 1)[0] + ":latest"
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

    image_uri = build_image(args.tag)

    if args.push:
        push_image(image_uri)

    print(f"\n✅ Build complete.")
    print(f"\nTo deploy each Cloud Run Job, override CMD:")
    for job_name, cmd in JOBS.items():
        print(f"  {job_name}: {cmd}")
    print(f"\nExample deploy:")
    print(f"  gcloud run jobs create {list(JOBS.keys())[0]} \\")
    print(f"    --image {image_uri} \\")
    print(f"    --command '{JOBS[list(JOBS.keys())[0]][0]}' \\")
    print(f"    --args '{','.join(JOBS[list(JOBS.keys())[0]][1:])}' \\")
    print(f"    --region {AR_REGION}")


if __name__ == "__main__":
    main()
