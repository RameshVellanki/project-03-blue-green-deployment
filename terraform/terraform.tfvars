# Copy this file to terraform.tfvars and update with your values
# terraform.tfvars is gitignored for security

project_id = "leafy-glyph-479507-m4"
region     = "us-central1"
zone       = "us-central1-a"

# Image names (built with Packer)
# These will be overridden by workflow environment variables
blue_image  = "webapp-blue-green-1-0-0-latest"
green_image = "webapp-blue-green-1-0-0-latest"

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
