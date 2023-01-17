variable "gcp_project" {
  description = "GCP project to deploy infrastructure to"
  type        = string
}
variable "gcp_region" {
  description = "The region we're deploying to"
  type        = string
  default     = "europe-west2"
}
variable "gcp_region_europe_west" {
  description = "London"
  type        = string
  default     = "europe-west2"
}
variable "gcp_region_us_central" {
  description = "Iowa"
  type        = string
  default     = "us-central1"
}
variable "gcp_zone" {
  description = "The default zone we're deploying to"
  type        = string
  default     = "europe-west2-a"
}
variable "gcp_zone_europe_west" {
  description = "The default zone we're deploying to"
  type        = string
  default     = "europe-west2-a"
}
variable "gcp_zone_us_central" {
  description = "The default zone we're deploying to"
  type        = string
  default     = "us-central1-a"
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
variable "container_registry" {
  description = "registry domain for google container registry"
  type        = string
  default     = "europe-west2-docker.pkg.dev"
}
variable "container_repository" {
  description = "repostiory name for google container registry"
  type        = string
  default     = "prod"
}

locals {
  api_service_account_id     = "${var.service_name_short}-api-sc-${var.environment}"
  fortune_service_account_id = "${var.service_name_short}-fortune-sc-${var.environment}"
}

provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
}
provider "google-beta" {
  alias   = "europe_west"
  project = var.gcp_project
  region  = var.gcp_region_europe_west
  zone    = var.gcp_zone_europe_west
}
provider "google-beta" {
  alias   = "us_central"
  project = var.gcp_project
  region  = var.gcp_region_us_central
  zone    = var.gcp_zone_us_central
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

resource "google_project_service" "cloudrun_api" {
  service = "run.googleapis.com"

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

resource "google_service_account" "api_account" {
  account_id   = local.api_service_account_id
  display_name = "Service account for the cloud fn api"
}

resource "google_service_account" "fortune_account" {
  account_id   = local.fortune_service_account_id
  display_name = "Service account for the fortune api"
}
