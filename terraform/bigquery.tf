# =============================================================================
# BigQuery Dataset (replaces Redshift Serverless)
# =============================================================================
# A single BigQuery dataset holds all tables. Unlike Redshift, BigQuery does
# not require separate schema provisioning — dbt creates tables directly.
#
# Logical layers within this dataset:
#   - RDL (Raw Data Layer): ingested source data from Cloud Run jobs
#   - ODL (Operational Data Layer): cleaned and transformed models
#   - ADL (Analytical Data Layer): business-ready aggregates and metrics
#   - unit_test: data quality staging and validation tables

resource "google_bigquery_dataset" "boohoo_dwh" {
  dataset_id  = "boohoo_dwh"
  project     = var.gcp_project_id
  location    = "EU"

  friendly_name = "Boohoo Data Warehouse"
  description   = <<-EOT
    Central data warehouse for the Boohoo data pipeline.
    Logical layers: RDL (Raw Data Layer), ODL (Operational Data Layer),
    ADL (Analytical Data Layer), unit_test (data quality staging).
    Tables are created and managed by dbt — do not create manually.
  EOT

  # Default table expiration disabled — dbt manages table lifecycle
  default_table_expiration_ms = null

  labels = {
    purpose = "data-warehouse"
  }

  lifecycle {
    prevent_destroy = true
  }
}
