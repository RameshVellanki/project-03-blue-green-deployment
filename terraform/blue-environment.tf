# Service Account for Blue Environment
resource "google_service_account" "blue_sa" {
  account_id   = "webapp-blue-sa"
  display_name = "Service Account for Blue Environment"
  description  = "Custom service account for blue environment instances with minimal permissions"
}

# IAM: Blue Logging
resource "google_project_iam_member" "blue_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.blue_sa.email}"
}

# IAM: Blue Monitoring
resource "google_project_iam_member" "blue_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.blue_sa.email}"
}

# Blue Environment Instance Template
resource "google_compute_instance_template" "blue" {
  name_prefix  = "blue-template-"
  machine_type = var.machine_type
  region       = var.region

  tags = ["http-server", "blue-server"]
  labels = merge(var.labels, {
    environment = "blue"
    version     = replace(var.blue_version, ".", "-")
  })

  disk {
    source_image = var.blue_image
    auto_delete  = true
    boot         = true
    disk_size_gb = 10
    disk_type    = "pd-standard"
  }

  network_interface {
    network = "default"
    
    access_config {
      # Ephemeral external IP
    }
  }

  service_account {
    email  = google_service_account.blue_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "FALSE"
    environment    = "blue"
    app_version    = var.blue_version
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Blue Environment Managed Instance Group
resource "google_compute_instance_group_manager" "blue" {
  name               = "blue-mig"
  base_instance_name = "blue-instance"
  zone               = var.zone
  target_size        = var.blue_instance_count

  version {
    instance_template = google_compute_instance_template.blue.id
  }

  named_port {
    name = "http"
    port = var.app_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.http_health_check.id
    initial_delay_sec = 300
  }

  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 2
    max_unavailable_fixed        = 0
    replacement_method           = "SUBSTITUTE"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_instance_template.blue,
    google_service_account.blue_sa,
    google_project_iam_member.blue_logging,
    google_project_iam_member.blue_monitoring
  ]
}

# Blue Environment Autoscaler
resource "google_compute_autoscaler" "blue" {
  name   = "blue-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.blue.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = var.blue_instance_count
    cooldown_period = 60

    cpu_utilization {
      target = 0.7
    }
  }
}
