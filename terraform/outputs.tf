# Load Balancer Outputs
output "lb_ip_address" {
  description = "External IP address of the load balancer"
  value       = google_compute_global_forwarding_rule.webapp.ip_address
}

output "lb_url" {
  description = "URL to access the load balancer"
  value       = "http://${google_compute_global_forwarding_rule.webapp.ip_address}"
}

# Active Environment
output "active_environment" {
  description = "Currently active environment receiving traffic"
  value       = var.active_environment
}

# Blue Environment Outputs
output "blue_mig_name" {
  description = "Name of the blue managed instance group"
  value       = google_compute_instance_group_manager.blue.name
}

output "blue_instance_count" {
  description = "Number of instances in blue MIG"
  value       = var.blue_instance_count
}

output "blue_version" {
  description = "Application version for blue environment"
  value       = var.blue_version
}

output "blue_image" {
  description = "Image used for blue environment"
  value       = var.blue_image
}

# Green Environment Outputs
output "green_mig_name" {
  description = "Name of the green managed instance group"
  value       = google_compute_instance_group_manager.green.name
}

output "green_instance_count" {
  description = "Number of instances in green MIG"
  value       = var.green_instance_count
}

output "green_version" {
  description = "Application version for green environment"
  value       = var.green_version
}

output "green_image" {
  description = "Image used for green environment"
  value       = var.green_image
}

# Service Account
output "service_account_email" {
  description = "Email of the service account"
  value       = google_service_account.webapp_sa.email
}

# Health Check
output "health_check_name" {
  description = "Name of the health check"
  value       = google_compute_health_check.http_health_check.name
}

# Backend Service
output "backend_service_name" {
  description = "Name of the backend service"
  value       = google_compute_backend_service.webapp.name
}

# Test Commands
output "test_commands" {
  description = "Commands to test the deployment"
  value = <<-EOT
    # Access the application
    curl http://${google_compute_global_forwarding_rule.webapp.ip_address}
    
    # Check health
    curl http://${google_compute_global_forwarding_rule.webapp.ip_address}/api/health
    
    # Check version (shows active environment)
    curl http://${google_compute_global_forwarding_rule.webapp.ip_address}/api/version
    
    # View instance info
    curl http://${google_compute_global_forwarding_rule.webapp.ip_address}/api/info
    
    # List blue instances
    gcloud compute instances list --filter="name:blue-instance"
    
    # List green instances
    gcloud compute instances list --filter="name:green-instance"
    
    # Switch traffic to green
    terraform apply -var="active_environment=green"
    
    # Rollback to blue
    terraform apply -var="active_environment=blue"
  EOT
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of the current deployment"
  value = <<-EOT
    Blue-Green Deployment Status:
    ==============================
    Active Environment: ${upper(var.active_environment)}
    Load Balancer IP: ${google_compute_global_forwarding_rule.webapp.ip_address}
    
    Blue Environment:
      - Image: ${var.blue_image}
      - Version: ${var.blue_version}
      - Instances: ${var.blue_instance_count}
      - Status: ${var.active_environment == "blue" ? "🔵 ACTIVE" : "⚪ STANDBY"}
    
    Green Environment:
      - Image: ${var.green_image}
      - Version: ${var.green_version}
      - Instances: ${var.green_instance_count}
      - Status: ${var.active_environment == "green" ? "🟢 ACTIVE" : "⚪ STANDBY"}
  EOT
}
