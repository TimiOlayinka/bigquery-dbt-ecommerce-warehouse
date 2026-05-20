# =============================================================================
# Boohoo Data Pipeline — GCP Terraform Configuration
# =============================================================================
# Provider, backend, and API enablement for the Boohoo DWH project.
# Region: europe-west2 (London) to maintain low latency for UK-based ops.

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Remote state in GCS — bucket must be created before first init.
  # Use: gsutil mb -l europe-west2 gs://boohoo-terraform-state-<project_id>
  backend "gcs" {
    bucket = "boohoo-terraform-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone

  default_labels = {
    project     = "boohoo-dwh"
    environment = var.environment
    managed_by  = "terraform"
  }
}

# =============================================================================
# Enable Required GCP APIs
# =============================================================================
# These APIs must be active before any resources can be provisioned.

locals {
  required_apis = [
    "compute.googleapis.com",
    "bigquery.googleapis.com",
    "cloudscheduler.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(local.required_apis)

  project = var.gcp_project_id
  service = each.value

  # Don't disable the API if this resource is destroyed — prevents
  # accidental breakage of resources outside Terraform's control.
  disable_on_destroy = false
}
