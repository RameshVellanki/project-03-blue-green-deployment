packer {
  required_version = ">= 1.9.0"
  
  required_plugins {
    googlecompute = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

# Variables
variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "zone" {
  type        = string
  description = "GCP zone for image building"
  default     = "us-central1-a"
}

variable "image_name" {
  type        = string
  description = "Name of the custom image"
  default     = "webapp-blue-green"
}

variable "image_family" {
  type        = string
  description = "Image family for organizing images"
  default     = "webapp"
}

variable "image_version" {
  type        = string
  description = "Application version to bake into image"
  default     = "1.0.0"
}

variable "source_image_family" {
  type        = string
  description = "Source image family to build from"
  default     = "ubuntu-2204-lts"
}

variable "machine_type" {
  type        = string
  description = "Machine type for image builder"
  default     = "e2-medium"
}

variable "disk_size" {
  type        = number
  description = "Disk size in GB"
  default     = 10
}

variable "disk_type" {
  type        = string
  description = "Disk type"
  default     = "pd-standard"
}

variable "network" {
  type        = string
  description = "Network to use for image building"
  default     = "default"
}

variable "tags" {
  type        = list(string)
  description = "Network tags for the builder instance"
  default     = ["packer-builder", "http-server"]
}

# Locals
locals {
  timestamp = formatdate("YYYYMMDDHHmmss", timestamp())
  # Truncate version to first 8 characters (short SHA) and sanitize
  short_version = substr(replace(var.image_version, ".", "-"), 0, 8)
  # Keep image name under 63 chars: webapp-<short-version>-<timestamp>
  image_name_full = "${var.image_name}-${local.short_version}-${local.timestamp}"
  
  labels = {
    environment = "packer-build"
    managed_by  = "packer"
    app_version = replace(var.image_version, ".", "-")
    created     = local.timestamp
  }
}

# Source configuration
source "googlecompute" "webapp" {
  # GCP Configuration
  project_id          = var.project_id
  zone                = var.zone
  
  # Source Image
  source_image_family = var.source_image_family
  
  # Output Image
  image_name          = local.image_name_full
  image_family        = var.image_family
  image_description   = "Web application image for blue-green deployment - v${var.image_version}"
  image_labels        = local.labels
  
  # Builder Instance
  machine_type        = var.machine_type
  disk_size           = var.disk_size
  disk_type           = var.disk_type
  network             = var.network
  tags                = var.tags
  
  # SSH Configuration
  ssh_username        = "packer"
  
  # Metadata
  metadata = {
    enable-oslogin = "FALSE"
    block-project-ssh-keys = "TRUE"
  }
  
  # Service Account
  # Uses default Compute Engine service account during build only
  # Production VMs will use custom service accounts
  omit_external_ip    = false
  use_internal_ip     = false
}

# Build configuration
build {
  name    = "webapp-blue-green"
  sources = ["source.googlecompute.webapp"]
  
  # Upload application files
  provisioner "file" {
    source      = "../scripts/app"
    destination = "/tmp"
  }
  
  # Upload provisioning script
  provisioner "file" {
    source      = "scripts/provision.sh"
    destination = "/tmp/provision.sh"
  }
  
  # Run provisioning script
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/provision.sh",
      "sudo APP_VERSION=${var.image_version} /tmp/provision.sh"
    ]
    environment_vars = [
      "APP_VERSION=${var.image_version}",
      "DEBIAN_FRONTEND=noninteractive"
    ]
  }
  
  # Verify installation
  provisioner "shell" {
    inline = [
      "echo 'Verifying Node.js installation...'",
      "node --version",
      "npm --version",
      "echo 'Verifying application files...'",
      "ls -la /opt/webapp",
      "echo 'Verifying systemd service...'",
      "systemctl list-unit-files | grep webapp || echo 'Service not yet enabled'",
      "echo 'Image build verification complete!'"
    ]
  }
  
  # Cleanup
  provisioner "shell" {
    inline = [
      "echo 'Cleaning up...'",
      "sudo apt-get clean",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*",
      "echo 'Cleanup complete!'"
    ]
  }
  
  # Post-processor: Manifest
  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
    custom_data = {
      version     = var.image_version
      timestamp   = local.timestamp
      image_name  = local.image_name_full
      image_family = var.image_family
    }
  }
}
