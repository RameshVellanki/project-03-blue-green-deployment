# GCP Configuration
project_id = "leafy-glyph-479507-m4"
region     = "us-central1"
zone       = "us-central1-a"

# Image placeholders (overridden by workflows with actual image names)
blue_image  = "webapp-blue-green-1-0-0-latest"
green_image = "webapp-blue-green-1-0-0-latest"

# Deployment control (managed automatically by deploy workflow)
deploy_blue  = false
deploy_green = false
active_environment = "blue"

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
