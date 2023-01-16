variable "gcp_project" {
  description = "GCP project to deploy infrastructure to"
  type        = string
}
variable "gcp_region" {
  description = "The region we're deploying to"
  type        = string
  default     = "europe-west2"
}
variable "gcp_zone" {
  description = "The default zone we're deploying to"
  type        = string
  default     = "europe-west2-a"
}
variable "environment" {
  description = "Environment key for namespacing infrastructure"
  type        = string
}
variable "commit_sha" {
  type = string
}
variable "build_number" {
  type = string
}
variable "service_name" {
  description = "The name of this service"
  type        = string
  default     = "cloud-functions-poc"
}
variable "service_name_short" {
  description = "Abbreviation of this service name"
  type        = string
  default     = "gcp-poc"
}
variable "function_runtime" {
  description = "Default runtime for cloud functions"
  type        = string
  default     = "nodejs18"
}

locals {
  build_version_ref = replace(var.commit_sha, "\"", "")
  log_level         = var.environment == "dev" ? "DEBUG" : "WARN"

  default_environment_variables = {
    LOG_LEVEL   = local.log_level
    ENVIRONMENT = var.environment
    REGION      = var.gcp_region
  }
}

provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
}

resource "google_project_service" "iam_api" {
  service = "iam.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}

resource "google_project_service" "cloudfunctions_api" {
  service = "cloudfunctions.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}

resource "google_project_service" "artifactregistry_api" {
  service = "artifactregistry.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}
resource "google_project_service" "cloudbuild_api" {
  service = "cloudbuild.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}
