# Service Account for all instances
resource "google_service_account" "webapp_sa" {
  account_id   = "webapp-blue-green-sa"
  display_name = "Service Account for Blue-Green Deployment"
  description  = "Custom service account for webapp instances with minimal permissions"
}

# IAM: Logging
resource "google_project_iam_member" "webapp_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.webapp_sa.email}"
}

# IAM: Monitoring
resource "google_project_iam_member" "webapp_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.webapp_sa.email}"
}

# Firewall rule: Allow health checks from Google Cloud health checkers
resource "google_compute_firewall" "allow_health_check" {
  name    = "allow-health-check"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = [var.app_port]
  }

  # Google Cloud health check IP ranges
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  target_tags = ["http-server", "blue-server", "green-server"]
  
  description = "Allow health checks from Google Cloud load balancers"
}

# Firewall rule: Allow HTTP from load balancer to backends
resource "google_compute_firewall" "allow_lb_to_backends" {
  name    = "allow-lb-to-backends"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = [var.app_port]
  }

  # Load balancer proxy IP ranges
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  target_tags = ["http-server", "blue-server", "green-server"]
  
  description = "Allow traffic from load balancer to backend instances"
}

# Health check for load balancer
resource "google_compute_health_check" "http_health_check" {
  name                = "webapp-http-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.app_port
    request_path = var.health_check_path
  }

  log_config {
    enable = true
  }
}
