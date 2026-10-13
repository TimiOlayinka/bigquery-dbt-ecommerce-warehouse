# =============================================================================
# GCS Buckets (replaces S3)
# =============================================================================
# Three buckets matching the AWS layout:
#   1. RDL Staging  — raw data landing zone for ingested source data
#   2. Terraform State — remote backend for Terraform state files
#   3. Data Quality — DuckDB dashboard exports and test results

# -----------------------------------------------------------------------------
# 1. RDL Staging Bucket
# -----------------------------------------------------------------------------
# Versioning enabled for data recovery. Lifecycle transitions objects to
# Nearline after 90 days (cost savings) and deletes after 365 days.

resource "google_storage_bucket" "rdl_staging" {
  name     = "omnistyle-rdl-staging-${var.gcp_project_id}"
  location = var.gcp_region
  project  = var.gcp_project_id

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    purpose = "rdl-staging"
  }
}

# -----------------------------------------------------------------------------
# 2. Terraform State Bucket
# -----------------------------------------------------------------------------
# Versioning enabled for state history and recovery.

resource "google_storage_bucket" "terraform_state" {
  name     = "omnistyle-terraform-state-${var.gcp_project_id}"
  location = var.gcp_region
  project  = var.gcp_project_id

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = {
    purpose = "terraform-state"
  }
}

# -----------------------------------------------------------------------------
# 3. Data Quality Bucket
# -----------------------------------------------------------------------------
# Stores Parquet exports for DuckDB dashboards and data quality test results.
# Objects auto-delete after 180 days.

resource "google_storage_bucket" "data_quality" {
  name     = "omnistyle-data-quality-${var.gcp_project_id}"
  location = var.gcp_region
  project  = var.gcp_project_id

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 180
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    purpose = "data-quality"
  }
}
