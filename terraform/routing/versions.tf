terraform {
  backend "gcs" {}
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.48.0"
    }
  }
  required_version = "~> 1.3.7"
}
