# =============================================================================
# Cloud Scheduler (replaces AWS EventBridge)
# =============================================================================
# One scheduler job per Cloud Run Job, triggering daily at midnight UTC.
# Each scheduler uses an HTTP target to invoke the Cloud Run Job execution API.

resource "google_cloud_scheduler_job" "trigger_data_generators" {
  for_each = toset(local.job_names)

  name    = "boohoo-trigger-${replace(each.value, "_", "-")}"
  project = var.gcp_project_id
  region  = var.gcp_region

  description = "Daily trigger for Cloud Run Job: ${each.value}"
  schedule    = "0 0 * * *"
  time_zone   = "UTC"

  # Ensure Cloud Scheduler API is enabled before creating jobs
  depends_on = [google_project_service.apis]

  http_target {
    http_method = "POST"

    # Cloud Run Jobs execution API endpoint
    uri = "https://${var.gcp_region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.gcp_project_id}/jobs/${google_cloud_run_v2_job.data_generators[each.key].name}:run"

    oauth_token {
      service_account_email = google_service_account.airflow_vm.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  retry_config {
    retry_count          = 3
    min_backoff_duration = "5s"
    max_backoff_duration = "60s"
    max_doublings        = 3
  }
}
