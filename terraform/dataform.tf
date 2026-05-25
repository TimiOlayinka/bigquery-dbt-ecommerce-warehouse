# =============================================================================
# Dataform IAM
# =============================================================================
# The Dataform repository was created manually in GCP Console.
# This file manages only the IAM grants needed for Dataform to operate.

# Get project number for service account reference
data "google_project" "current" {
  project_id = var.gcp_project_id
}

# Grant Dataform service account BigQuery admin access
resource "google_project_iam_member" "dataform_bigquery_admin" {
  project = var.gcp_project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}
