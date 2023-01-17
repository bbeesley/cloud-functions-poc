variable "gcp_project" {
  description = "GCP project to deploy infrastructure to"
  type        = string
}
variable "gcp_region" {
  description = "The region we're deploying to"
  type        = string
}
variable "gcp_zone" {
  description = "The default zone we're deploying to"
  type        = string
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
}
variable "service_name_short" {
  description = "Abbreviation of this service name"
  type        = string
}
variable "function_runtime" {
  description = "Default runtime for cloud functions"
  type        = string
}
variable "container_registry" {
  description = "registry domain for google container registry"
  type        = string
}
variable "container_repository" {
  description = "repostiory name for google container registry"
  type        = string
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
