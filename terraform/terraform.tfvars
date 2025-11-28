# Copy this file to terraform.tfvars and update with your values
# terraform.tfvars is gitignored for security

project_id = "leafy-glyph-479507-m4"
region     = "us-central1"
zone       = "us-central1-a"

# Image names (built with Packer)
blue_image  = "webapp-blue-green-v1-0-0-20250101000000"
green_image = "webapp-blue-green-v2-0-0-20250101000000"

# Active environment (blue or green)
active_environment = "blue"

# Application versions
blue_version  = "1.0.0"
green_version = "2.0.0"

# Instance configuration
machine_type         = "e2-micro"
blue_instance_count  = 2
green_instance_count = 2

labels = {
  project     = "gcp-learning"
  environment = "dev"
  managed_by  = "terraform"
  deployment  = "blue-green"
}
