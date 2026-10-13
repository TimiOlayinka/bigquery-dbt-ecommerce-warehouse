# =============================================================================
# Secret Manager (replaces AWS Secrets Manager)
# =============================================================================
# BigQuery authenticates via IAM — no database credentials needed.
# This secret serves as a placeholder for Airflow configuration and
# any future API keys (e.g. Meta Ads, Google Ads, TikTok tokens).

resource "google_secret_manager_secret" "airflow_config" {
  secret_id = "omnistyle-airflow-config"
  project   = var.gcp_project_id

  replication {
    auto {}
  }

  labels = {
    purpose = "airflow-config"
  }

  depends_on = [google_project_service.apis]
}

# Placeholder version — replace with actual config via gcloud or CI/CD
resource "google_secret_manager_secret_version" "airflow_config_placeholder" {
  secret = google_secret_manager_secret.airflow_config.id
  secret_data = jsonencode({
    description = "Placeholder — update with actual Airflow configuration"
    bigquery    = "Uses IAM authentication, no credentials required"
    api_keys    = {}
  })
}
