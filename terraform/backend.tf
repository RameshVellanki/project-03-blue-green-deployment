terraform {
  backend "gcs" {
    bucket = "tftbk"
    prefix = "project-03-blue-green-deployment/terraform.tfstate"
  }
}
