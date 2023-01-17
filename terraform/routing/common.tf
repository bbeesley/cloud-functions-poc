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
variable "dns_zone" {
  description = "Cloud DNS zone that the domain is managed from"
  type        = string
  default     = "beesley-app"
}
variable "domain_name" {
  description = "Domain to route traffic from"
  type        = string
}
variable "run_regions" {
  type    = list(string)
  default = ["europe-west2", "us-central1"]
}

locals {
  build_version_ref = replace(var.commit_sha, "\"", "")
}

provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
}

resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}
