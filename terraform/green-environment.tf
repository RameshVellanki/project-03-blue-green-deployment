# Green Environment Instance Template
resource "google_compute_instance_template" "green" {
  name_prefix  = "green-template-"
  machine_type = var.machine_type
  region       = var.region

  tags = ["http-server", "green-server"]
  labels = merge(var.labels, {
    environment = "green"
    version     = replace(var.green_version, ".", "-")
  })

  disk {
    source_image = var.green_image
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
    email  = google_service_account.webapp_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "FALSE"
    environment    = "green"
    app_version    = var.green_version
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Green Environment Managed Instance Group
resource "google_compute_instance_group_manager" "green" {
  name               = "green-mig"
  base_instance_name = "green-instance"
  zone               = var.zone
  target_size        = var.green_instance_count

  version {
    instance_template = google_compute_instance_template.green.id
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
    google_compute_instance_template.green,
    google_service_account.webapp_sa,
    google_project_iam_member.webapp_logging,
    google_project_iam_member.webapp_monitoring
  ]
}

# Green Environment Autoscaler
resource "google_compute_autoscaler" "green" {
  name   = "green-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.green.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = var.green_instance_count
    cooldown_period = 60

    cpu_utilization {
      target = 0.7
    }
  }
}
