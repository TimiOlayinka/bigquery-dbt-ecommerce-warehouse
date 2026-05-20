# =============================================================================
# IAM — Service Accounts & Role Bindings
# =============================================================================
# Two service accounts with least-privilege access:
#   1. boohoo-data-generator — Cloud Run Jobs (write to GCS, query BigQuery)
#   2. boohoo-airflow-vm     — Compute Engine (read GCS, admin BigQuery, invoke Cloud Run)

# -----------------------------------------------------------------------------
# 1. Data Generator Service Account (Cloud Run Jobs)
# -----------------------------------------------------------------------------

resource "google_service_account" "data_generator" {
  account_id   = "boohoo-data-generator"
  display_name = "Boohoo Data Generator"
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
  account_id   = "boohoo-airflow-vm"
  display_name = "Boohoo Airflow VM"
  description  = "Service account for the Airflow orchestrator VM"
  project      = var.gcp_project_id
}

# GCS: read data from staging buckets
resource "google_project_iam_member" "airflow_vm_gcs_viewer" {
  project = var.gcp_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.airflow_vm.email}"
}

# BigQuery: full admin for dbt model execution
resource "google_project_iam_member" "airflow_vm_bq_admin" {
  project = var.gcp_project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.airflow_vm.email}"
}

# Cloud Run: invoke jobs from Airflow DAGs
resource "google_project_iam_member" "airflow_vm_run_invoker" {
  project = var.gcp_project_id
  role    = "roles/run.invoker"
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

resource "google_artifact_registry_repository" "boohoo_jobs" {
  location      = var.gcp_region
  repository_id = "boohoo-jobs"
  description   = "Docker images for Boohoo data generator Cloud Run Jobs"
  format        = "DOCKER"
  project       = var.gcp_project_id

  depends_on = [google_project_service.apis]
}
