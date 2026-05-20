# =============================================================================
# Variables
# =============================================================================

variable "gcp_project_id" {
  description = "GCP project ID — must be provided (no default for safety)"
  type        = string

  validation {
    condition     = length(var.gcp_project_id) > 0
    error_message = "gcp_project_id must not be empty."
  }
}

variable "gcp_region" {
  description = "GCP region for all regional resources"
  type        = string
  default     = "europe-west2"
}

variable "gcp_zone" {
  description = "GCP zone for zonal resources (Compute Engine)"
  type        = string
  default     = "europe-west2-a"
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging, dev)"
  type        = string
  default     = "prod"
}

variable "vm_machine_type" {
  description = "Compute Engine machine type for the Airflow VM"
  type        = string
  default     = "e2-standard-2"
}

variable "scheduler_start_cron" {
  description = "Cron schedule to start the Airflow VM (UTC)"
  type        = string
  default     = "0 1 * * 1,3,5" # Mon/Wed/Fri at 01:00 UTC
}

variable "scheduler_stop_cron" {
  description = "Cron schedule to stop the Airflow VM (UTC)"
  type        = string
  default     = "0 3 * * 1,3,5" # Mon/Wed/Fri at 03:00 UTC
}
