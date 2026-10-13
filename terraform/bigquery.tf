# =============================================================================
# BigQuery Datasets & External Tables
# =============================================================================
# Datasets organised by data layer:
#   - rdl_<brand>: One dataset per brand with external tables pointing at GCS
#   - odl:         Unified dimensions + facts (managed by Dataform)
#   - bi:          Aggregated analytics for BI dashboards (managed by Dataform)

# -----------------------------------------------------------------------------
# Datasets
# -----------------------------------------------------------------------------

resource "google_bigquery_dataset" "rdl_brand" {
  for_each = toset([
    "rdl_velvet_lane",
    "rdl_velvet_mens",
    "rdl_trend_pulse",
    "rdl_rebel_chic",
    "rdl_atelier_luxe",
    "rdl_riviera_mode",
    "rdl_grand_heritage",
  ])

  dataset_id    = each.key
  project       = var.gcp_project_id
  location      = "EU"
  friendly_name = "Raw Data Layer - ${replace(each.key, "_", " ")}"
  description   = <<-EOT
    Brand-specific raw data layer with external tables pointing at GCS.
    Managed by Terraform. Do not create tables manually.
  EOT

  labels = { layer = "rdl", managed_by = "terraform" }
}

resource "google_bigquery_dataset" "odl" {
  dataset_id    = "odl"
  project       = var.gcp_project_id
  location      = "EU"
  friendly_name = "Operational Data Layer"
  description   = <<-EOT
    Unified dimension and fact tables across all brands.
    Managed by Dataform. Do not create tables manually.
  EOT

  labels = { layer = "odl", managed_by = "dataform" }
}

resource "google_bigquery_dataset" "bi" {
  dataset_id    = "bi"
  project       = var.gcp_project_id
  location      = "EU"
  friendly_name = "Business Intelligence Layer"
  description   = <<-EOT
    Pre-aggregated analytics tables for BI dashboards.
    Managed by Dataform. Do not create tables manually.
  EOT

  labels = { layer = "bi", managed_by = "dataform" }
}

# -----------------------------------------------------------------------------
# External Tables — E-Commerce
# -----------------------------------------------------------------------------

locals {
  ecommerce_brands = {
    velvet_lane    = ["customers", "orders", "products"]
    velvet_mens    = ["customers", "orders", "products"]
    trend_pulse    = ["customers", "orders", "products"]
    rebel_chic     = ["customers", "orders", "products"]
    atelier_luxe   = ["customers", "orders", "products"]
    riviera_mode   = ["customers", "orders", "products"]
    grand_heritage = ["customers", "orders", "products"]
  }

  # Flatten into a map of key => { brand, dataset }
  ecommerce_tables = merge([
    for brand, datasets in local.ecommerce_brands : {
      for dataset in datasets :
      "${brand}_${dataset}_stg" => {
        brand   = brand
        dataset = dataset
      }
    }
  ]...)

  # Marketing: all 7 brands × 6 channels
  marketing_brands   = ["velvet_lane", "velvet_mens", "trend_pulse", "rebel_chic", "atelier_luxe", "riviera_mode", "grand_heritage"]
  marketing_channels = ["meta_ads", "google_ads", "tiktok_ads", "ga4_sessions", "email_campaigns", "influencers"]

  marketing_tables = {
    for pair in setproduct(local.marketing_brands, local.marketing_channels) :
    "${pair[0]}_${pair[1]}_stg" => {
      brand   = pair[0]
      dataset = pair[1]
    }
  }
}

resource "google_bigquery_table" "ecommerce_external" {
  for_each            = local.ecommerce_tables
  project             = var.gcp_project_id
  dataset_id          = google_bigquery_dataset.rdl_brand["rdl_${each.value.brand}"].dataset_id
  table_id            = "${each.value.dataset}_stg"
  deletion_protection = false

  external_data_configuration {
    source_format = "NEWLINE_DELIMITED_JSON"
    autodetect    = true
    compression   = "GZIP"
    source_uris = [
      "gs://${var.gcs_bucket}/raw/${each.value.brand}/${each.value.dataset}/*"
    ]

    hive_partitioning_options {
      mode              = "AUTO"
      source_uri_prefix = "gs://${var.gcs_bucket}/raw/${each.value.brand}/${each.value.dataset}/"
    }
  }

  labels = {
    layer = "rdl"
    brand = each.value.brand
  }
}

# -----------------------------------------------------------------------------
# External Tables — Marketing
# -----------------------------------------------------------------------------

resource "google_bigquery_table" "marketing_external" {
  for_each            = local.marketing_tables
  project             = var.gcp_project_id
  dataset_id          = google_bigquery_dataset.rdl_brand["rdl_${each.value.brand}"].dataset_id
  table_id            = "${each.value.dataset}_stg"
  deletion_protection = false

  external_data_configuration {
    source_format = "NEWLINE_DELIMITED_JSON"
    autodetect    = true
    compression   = "GZIP"
    source_uris = [
      "gs://${var.gcs_bucket}/raw/${each.value.brand}/${each.value.dataset}/*"
    ]

    hive_partitioning_options {
      mode              = "AUTO"
      source_uri_prefix = "gs://${var.gcs_bucket}/raw/${each.value.brand}/${each.value.dataset}/"
    }
  }

  labels = {
    layer = "rdl"
    brand = each.value.brand
  }
}
