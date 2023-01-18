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

resource "google_service_account_iam_binding" "fortune_account_logging" {
  service_account_id = google_service_account.fortune_account.name
  role               = "roles/logging.logWriter"
  members = [
    "allUsers",
  ]
}

resource "google_service_account_iam_binding" "api_account_logging" {
  service_account_id = google_service_account.api_account.name
  role               = "roles/logging.logWriter"
  members = [
    "allUsers",
  ]
}
