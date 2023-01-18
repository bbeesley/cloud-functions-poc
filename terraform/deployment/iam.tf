locals {
  api_service_account_id     = "${var.service_name_short}-api-sc-${var.environment}"
  fortune_service_account_id = "${var.service_name_short}-fortune-sc-${var.environment}"
}

resource "google_service_account" "api_account" {
  account_id   = local.api_service_account_id
  display_name = "Service account for the cloud fn api"
}

resource "google_service_account" "fortune_account" {
  account_id   = local.fortune_service_account_id
  display_name = "Service account for the fortune api"
}

resource "google_project_iam_binding" "logging" {
  project = var.gcp_project
  role    = "roles/logging.logWriter"
  members = [
    "serviceAccount:${google_service_account.fortune_account.email}",
    "serviceAccount:${google_service_account.api_account.email}",
  ]
}

resource "google_project_iam_binding" "tracing" {
  project = var.gcp_project
  role    = "roles/cloudtrace.agent"
  members = [
    "serviceAccount:${google_service_account.fortune_account.email}",
    "serviceAccount:${google_service_account.api_account.email}",
  ]
}
