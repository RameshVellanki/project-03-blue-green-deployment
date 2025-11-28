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

# Backend Service - Points to active environment
resource "google_compute_backend_service" "webapp" {
  name                  = "webapp-backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  enable_cdn            = false
  health_checks         = [google_compute_health_check.http_health_check.id]
  load_balancing_scheme = "EXTERNAL"

  # Backend points to active environment
  backend {
    group           = var.active_environment == "blue" ? google_compute_instance_group_manager.blue.instance_group : google_compute_instance_group_manager.green.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# URL Map
resource "google_compute_url_map" "webapp" {
  name            = "webapp-url-map"
  default_service = google_compute_backend_service.webapp.id
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "webapp" {
  name    = "webapp-http-proxy"
  url_map = google_compute_url_map.webapp.id
}

# Global Forwarding Rule (External IP and Port)
resource "google_compute_global_forwarding_rule" "webapp" {
  name                  = "webapp-forwarding-rule"
  target                = google_compute_target_http_proxy.webapp.id
  port_range            = "80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
}

# Firewall rule: Allow HTTP from internet to load balancer
resource "google_compute_firewall" "allow_http_from_internet" {
  name    = "allow-http-from-internet"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
  
  description = "Allow HTTP traffic from internet to load balancer"
}
