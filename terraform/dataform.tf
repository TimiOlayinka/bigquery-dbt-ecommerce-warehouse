# =============================================================================
# Dataform Repository
# =============================================================================
# Connects Dataform to the GitHub repo for SQL transformation management.
# Dataform replaces dbt as the transformation engine — runs natively in GCP.

resource "google_dataform_repository" "boohoo_pipeline" {
  provider = google
  name     = "boohoo-data-pipeline"
  region   = var.gcp_region
  project  = var.gcp_project_id

  git_remote_settings {
    url            = "https://github.com/TimiOlayinka/boohoo-data-pipeline.git"
    default_branch = "main"
    authentication_token_secret_version = "${google_secret_manager_secret.dataform_github_token.id}/versions/latest"
  }

  workspace_compilation_overrides {
    default_database = var.gcp_project_id
  }
}

# Secret for GitHub PAT (the value is set manually via Console)
resource "google_secret_manager_secret" "dataform_github_token" {
  secret_id = "dataform-github-token"
  project   = var.gcp_project_id

  replication {
    auto {}
  }

  labels = {
    purpose    = "dataform"
    managed_by = "terraform"
  }
}

# Grant Dataform service account access to the secret
resource "google_secret_manager_secret_iam_member" "dataform_secret_access" {
  project   = var.gcp_project_id
  secret_id = google_secret_manager_secret.dataform_github_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

# Get project number for service account reference
data "google_project" "current" {
  project_id = var.gcp_project_id
}

# Grant Dataform service account BigQuery access
resource "google_project_iam_member" "dataform_bigquery_admin" {
  project = var.gcp_project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}
