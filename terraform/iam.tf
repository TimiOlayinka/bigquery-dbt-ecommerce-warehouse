# =============================================================================
# IAM — Service Accounts & Role Bindings
# =============================================================================
# Two service accounts with least-privilege access:
#   1. omnistyle-data-generator — Cloud Run Jobs (write to GCS, query BigQuery)
#   2. omnistyle-airflow-vm     — Compute Engine (read GCS, admin BigQuery, invoke Cloud Run)

# -----------------------------------------------------------------------------
# 1. Data Generator Service Account (Cloud Run Jobs)
# -----------------------------------------------------------------------------

resource "google_service_account" "data_generator" {
  account_id   = "omnistyle-data-generator"
  display_name = "VelvetLane Data Generator"
  description  = "Service account for Cloud Run data generator jobs"
  project      = var.gcp_project_id
}

# GCS: write raw data to the RDL staging bucket
resource "google_storage_bucket_iam_member" "data_generator_gcs" {
  bucket = google_storage_bucket.rdl_staging.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.data_generator.email}"
}

# BigQuery: create/update tables and run queries
resource "google_project_iam_member" "data_generator_bq_editor" {
  project = var.gcp_project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.data_generator.email}"
}

resource "google_project_iam_member" "data_generator_bq_job_user" {
  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.data_generator.email}"
}

# -----------------------------------------------------------------------------
# 2. Airflow VM Service Account (Compute Engine)
# -----------------------------------------------------------------------------

resource "google_service_account" "airflow_vm" {
  account_id   = "omnistyle-airflow-vm"
  display_name = "VelvetLane Airflow VM"
  description  = "Service account for the Airflow orchestrator VM"
  project      = var.gcp_project_id
}

# GCS: read data from staging buckets
resource "google_project_iam_member" "airflow_vm_gcs_viewer" {
  project = var.gcp_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.airflow_vm.email}"
}

# BigQuery: full admin for Dataform model execution
resource "google_project_iam_member" "airflow_vm_bq_admin" {
  project = var.gcp_project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.airflow_vm.email}"
}

# Cloud Run: invoke and monitor jobs from Airflow DAGs
resource "google_project_iam_member" "airflow_vm_run_developer" {
  project = var.gcp_project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.airflow_vm.email}"
}

# Secret Manager: access pipeline secrets
resource "google_project_iam_member" "airflow_vm_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.airflow_vm.email}"
}

# =============================================================================
# Artifact Registry — Docker Image Repository
# =============================================================================
# Stores container images for Cloud Run Jobs, pushed by CI/CD pipeline.

resource "google_artifact_registry_repository" "velvet_lane_jobs" {
  location      = var.gcp_region
  repository_id = "omnistyle-jobs"
  description   = "Docker images for VelvetLane data generator Cloud Run Jobs"
  format        = "DOCKER"
  project       = var.gcp_project_id

  depends_on = [google_project_service.apis]
}

# =============================================================================
# Cloud Build CI/CD Service Account
# =============================================================================
# Used by Cloud Build triggers to build and push Docker images.

resource "google_service_account" "cloud_builder" {
  account_id   = "omnistyle-cloud-builder"
  display_name = "VelvetLane Cloud Builder"
  description  = "Service account for Cloud Build CI/CD pipeline"
  project      = var.gcp_project_id
}

# Allow Cloud Build to write logs
resource "google_project_iam_member" "cloud_builder_logs" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_builder.email}"
}

# Allow Cloud Build to push Docker images to Artifact Registry
resource "google_project_iam_member" "cloud_builder_ar_writer" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cloud_builder.email}"
}
