variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for resources"
  type        = string
  default     = "us-central1-a"
}

variable "blue_image" {
  description = "Custom image for blue environment"
  type        = string
  default     = "webapp-blue-green-v1-0-0-latest"
}

variable "green_image" {
  description = "Custom image for green environment"
  type        = string
  default     = "webapp-blue-green-v1-0-0-latest"
}

variable "active_environment" {
  description = "Active environment receiving traffic (blue or green)"
  type        = string
  default     = "blue"
  
  validation {
    condition     = contains(["blue", "green"], var.active_environment)
    error_message = "active_environment must be either 'blue' or 'green'"
  }
}

variable "blue_version" {
  description = "Application version for blue environment"
  type        = string
  default     = "1.0.0"
}

variable "green_version" {
  description = "Application version for green environment"
  type        = string
  default     = "1.0.0"
}

variable "machine_type" {
  description = "Machine type for instances"
  type        = string
  default     = "e2-micro"
}

variable "blue_instance_count" {
  description = "Number of instances in blue MIG"
  type        = number
  default     = 2
}

variable "green_instance_count" {
  description = "Number of instances in green MIG"
  type        = number
  default     = 2
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/api/health"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    project     = "gcp-learning"
    environment = "dev"
    managed_by  = "terraform"
    deployment  = "blue-green"
  }
}
