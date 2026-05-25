# =============================================================================
# Cloud Run Jobs (replaces AWS Lambda)
# =============================================================================
# Each data generator runs as a Cloud Run Job pulling a container image from
# Artifact Registry. Jobs are triggered on schedule by Cloud Scheduler.

locals {
  job_names = [
    "ecommerce_customers",
    "ecommerce_orders",
    "ecommerce_products",
    "marketing_meta_ads",
    "marketing_google_ads",
    "marketing_tiktok_ads",
    "marketing_ga4_sessions",
    "marketing_email_campaigns",
    "marketing_influencers",
  ]
}

resource "google_cloud_run_v2_job" "data_generators" {
  for_each = toset(local.job_names)

  name     = "boohoo-${replace(each.value, "_", "-")}"
  location = var.gcp_region
  project  = var.gcp_project_id

  # Ensure Cloud Run API is enabled before creating jobs
  depends_on = [google_project_service.apis]

  template {
    task_count  = 1
    parallelism = 1

    template {
      max_retries = 2
      timeout     = "300s"

      service_account = google_service_account.data_generator.email

      containers {
        # Image from Artifact Registry — pushed by CI/CD pipeline
        image = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/boohoo-jobs/${each.value}:latest"

        command = ["python", "-m", "${each.value}.main"]

        resources {
          limits = {
            memory = "512Mi"
            cpu    = "1"
          }
        }

        env {
          name  = "GCS_BUCKET"
          value = google_storage_bucket.rdl_staging.name
        }

        env {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      }
    }
  }

  labels = {
    pipeline = replace(each.value, "_", "-")
  }

  lifecycle {
    ignore_changes = [
      # Don't redeploy if image tag changes outside Terraform (CI/CD pushes)
      template[0].template[0].containers[0].image,
    ]
  }
}
