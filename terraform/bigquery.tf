# =============================================================================
# BigQuery Datasets & External Tables
# =============================================================================
# 4 datasets organised by data layer:
#   - rdl_raw: External tables pointing at GCS (no BQ storage cost)
#   - rdl:     Cleaned/versioned views (managed by Dataform)
#   - odl:     Unified dimensions + facts (managed by Dataform)
#   - bi:      Aggregated analytics for BI dashboards (managed by Dataform)

# -----------------------------------------------------------------------------
# Datasets
# -----------------------------------------------------------------------------

resource "google_bigquery_dataset" "rdl_raw" {
  dataset_id    = "rdl_raw"
  project       = var.gcp_project_id
  location      = "EU"
  friendly_name = "Raw Data Layer - External Tables"
  description   = <<-EOT
    External tables pointing at GCS JSONL.GZ files.
    No BigQuery storage cost — data stays in GCS.
    Managed by Terraform. Do not create tables manually.
  EOT

  labels = { layer = "rdl-raw", managed_by = "terraform" }
}

resource "google_bigquery_dataset" "rdl" {
  dataset_id    = "rdl"
  project       = var.gcp_project_id
  location      = "EU"
  friendly_name = "Raw Data Layer - Cleaned Views"
  description   = <<-EOT
    Cleaned and versioned views over raw external tables.
    Managed by Dataform. Do not create tables manually.
  EOT

  labels = { layer = "rdl", managed_by = "dataform" }
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
  ecommerce_sources = {
    boohoo_commerce = {
      brands = {
        boohoo     = ["customers", "orders", "products"]
        boohoo_man = ["customers", "orders", "products"]
      }
    }
    salesforce_commerce = {
      brands = {
        prettylittlething = { datasets = ["customers", "orders", "products"], prefix = "plt" }
      }
    }
    shopify = {
      brands = {
        nastygal = ["customers", "orders", "products"]
      }
    }
    magento = {
      brands = {
        karen_millen = ["customers", "orders", "products"]
        coast        = ["customers", "orders", "products"]
      }
    }
    oracle_commerce = {
      brands = {
        debenhams = ["customers", "orders", "products"]
      }
    }
  }

  # Flatten ecommerce sources into a map of table_id => { source, brand, dataset }
  ecommerce_tables = merge([
    for source, config in local.ecommerce_sources : merge([
      for brand, brand_config in config.brands : {
        for dataset in try(brand_config.datasets, brand_config) :
        "${try(brand_config.prefix, brand)}_${dataset}_history" => {
          source  = source
          brand   = brand
          dataset = dataset
        }
      }
    ]...)
  ]...)

  # Marketing: all 7 brands × 6 channels
  marketing_brands   = ["boohoo", "boohoo_man", "prettylittlething", "nastygal", "karen_millen", "coast", "debenhams"]
  marketing_datasets = ["meta_ads", "google_ads", "tiktok_ads", "ga4_sessions", "email_campaigns", "influencers"]

  marketing_tables = {
    for pair in setproduct(local.marketing_brands, local.marketing_datasets) :
    "${pair[0]}_${pair[1]}_history" => {
      source  = "marketing"
      brand   = pair[0]
      dataset = pair[1]
    }
  }
}

resource "google_bigquery_table" "ecommerce_external" {
  for_each   = local.ecommerce_tables
  project    = var.gcp_project_id
  dataset_id = google_bigquery_dataset.rdl_raw.dataset_id
  table_id   = each.key
  deletion_protection = false

  external_data_configuration {
    source_format = "NEWLINE_DELIMITED_JSON"
    autodetect    = true
    compression   = "GZIP"
    source_uris = [
      "gs://${var.gcs_bucket}/raw/${each.value.source}/${each.value.brand}/${each.value.dataset}/*"
    ]

    hive_partitioning_options {
      mode              = "AUTO"
      source_uri_prefix = "gs://${var.gcs_bucket}/raw/${each.value.source}/${each.value.brand}/${each.value.dataset}/"
    }
  }

  labels = {
    layer         = "rdl-raw"
    source_system = each.value.source
    brand         = each.value.brand
  }
}

# -----------------------------------------------------------------------------
# External Tables — Marketing
# -----------------------------------------------------------------------------

resource "google_bigquery_table" "marketing_external" {
  for_each   = local.marketing_tables
  project    = var.gcp_project_id
  dataset_id = google_bigquery_dataset.rdl_raw.dataset_id
  table_id   = each.key
  deletion_protection = false

  external_data_configuration {
    source_format = "NEWLINE_DELIMITED_JSON"
    autodetect    = true
    compression   = "GZIP"
    source_uris = [
      "gs://${var.gcs_bucket}/raw/${each.value.source}/${each.value.brand}/${each.value.dataset}/*"
    ]

    hive_partitioning_options {
      mode              = "AUTO"
      source_uri_prefix = "gs://${var.gcs_bucket}/raw/${each.value.source}/${each.value.brand}/${each.value.dataset}/"
    }
  }

  labels = {
    layer         = "rdl-raw"
    source_system = "marketing"
    brand         = each.value.brand
  }
}
