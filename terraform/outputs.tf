# =============================================================================
# Outputs
# =============================================================================

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID for the Boohoo DWH"
  value       = google_bigquery_dataset.boohoo_dwh.dataset_id
}

output "rdl_staging_bucket" {
  description = "GCS bucket for raw data landing (RDL)"
  value       = google_storage_bucket.rdl_staging.name
}

output "data_quality_bucket" {
  description = "GCS bucket for data quality exports and test results"
  value       = google_storage_bucket.data_quality.name
}

output "airflow_external_ip" {
  description = "Static external IP for the Airflow VM (use http://<ip>:8081)"
  value       = google_compute_address.airflow.address
}

output "airflow_instance_name" {
  description = "Compute Engine instance name for the Airflow VM"
  value       = google_compute_instance.airflow.name
}

output "cloud_run_job_names" {
  description = "List of all deployed Cloud Run Job names"
  value       = [for job in google_cloud_run_v2_job.data_generators : job.name]
}

output "artifact_registry_url" {
  description = "Artifact Registry URL for pushing Docker images"
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.boohoo_jobs.repository_id}"
}

output "data_generator_service_account_email" {
  description = "Service account email used by Cloud Run data generator jobs"
  value       = google_service_account.data_generator.email
}

output "airflow_service_account_email" {
  description = "Service account email used by the Airflow Compute Engine VM"
  value       = google_service_account.airflow_vm.email
}
