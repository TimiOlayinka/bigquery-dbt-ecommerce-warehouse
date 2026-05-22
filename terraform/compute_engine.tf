# =============================================================================
# Compute Engine — Airflow VM (replaces AWS EC2)
# =============================================================================
# A single VM running Apache Airflow via Docker Compose, with a static
# external IP and firewall rules for SSH and the Airflow web UI.

# -----------------------------------------------------------------------------
# Static External IP
# -----------------------------------------------------------------------------
# Persists across VM stop/start cycles (equivalent to AWS Elastic IP).

resource "google_compute_address" "airflow" {
  name    = "boohoo-airflow-ip"
  project = var.gcp_project_id
  region  = var.gcp_region
}

# -----------------------------------------------------------------------------
# VPC Network & Firewall
# -----------------------------------------------------------------------------
# Using default network for simplicity. Firewall rules allow SSH (22) and
# Airflow UI (8081) access.

resource "google_compute_firewall" "airflow_ssh" {
  name    = "boohoo-airflow-allow-ssh"
  project = var.gcp_project_id
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["airflow"]

  description = "Allow SSH access to Airflow VM"
}

resource "google_compute_firewall" "airflow_ui" {
  name    = "boohoo-airflow-allow-ui"
  project = var.gcp_project_id
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8081"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["airflow"]

  description = "Allow Airflow Web UI access on port 8081"
}

# -----------------------------------------------------------------------------
# Instance Schedule (replaces EC2 scheduler Lambda + EventBridge)
# -----------------------------------------------------------------------------
# Native GCE resource policy for automatic start/stop — no Lambda needed.

resource "google_compute_resource_policy" "airflow_schedule" {
  name    = "boohoo-airflow-schedule"
  project = var.gcp_project_id
  region  = var.gcp_region

  description = "Auto start/stop Airflow VM on Mon/Wed/Fri (UTC)"

  instance_schedule_policy {
    vm_start_schedule {
      schedule = var.scheduler_start_cron
    }

    vm_stop_schedule {
      schedule = var.scheduler_stop_cron
    }

    time_zone = "UTC"
  }
}

# -----------------------------------------------------------------------------
# Compute Engine Instance
# -----------------------------------------------------------------------------

resource "google_compute_instance" "airflow" {
  name         = "boohoo-airflow"
  machine_type = var.vm_machine_type
  zone         = var.gcp_zone
  project      = var.gcp_project_id

  tags = ["airflow"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"

    access_config {
      # Static external IP — persists across stop/start cycles
      nat_ip = google_compute_address.airflow.address
    }
  }

  service_account {
    email  = google_service_account.airflow_vm.email
    scopes = ["cloud-platform"]
  }

  # Attach the instance schedule for auto start/stop
  resource_policies = [google_compute_resource_policy.airflow_schedule.id]

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # -------------------------------------------------------------------------
    # Swap file (1GB) — needed for e2-standard-2 running Docker + Airflow
    # -------------------------------------------------------------------------
    if [ ! -f /swapfile ]; then
      fallocate -l 1G /swapfile
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
    fi

    # -------------------------------------------------------------------------
    # Install Docker & Docker Compose
    # -------------------------------------------------------------------------
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg git

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    # -------------------------------------------------------------------------
    # Clone repo and start Airflow via Docker Compose
    # -------------------------------------------------------------------------
    REPO_DIR="/opt/boohoo-repo"
    if [ ! -d "$REPO_DIR" ]; then
      git clone https://github.com/TimiOlayinka/boohoo-data-pipeline.git "$REPO_DIR"
    else
      cd "$REPO_DIR" && git pull origin main
    fi

    cd "$REPO_DIR"

    # Start Airflow stack using the cloud-specific compose file
    if [ -f airflow/docker-compose.cloud.yaml ]; then
      cd airflow && docker compose -f docker-compose.cloud.yaml down --remove-orphans 2>/dev/null || true
      docker compose -f docker-compose.cloud.yaml up -d
    fi

    echo "Startup script completed at $(date)" >> /var/log/boohoo-startup.log
  EOF

  labels = {
    purpose = "airflow-orchestrator"
  }

  # Allow Terraform to stop the VM for updates
  allow_stopping_for_update = true

  depends_on = [
    google_project_service.apis,
    google_compute_firewall.airflow_ssh,
    google_compute_firewall.airflow_ui,
  ]
}
