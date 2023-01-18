module "service_europe_west" {
  source = "../service"

  providers = {
    google-beta = google-beta.europe_west
  }
  gcp_project          = var.gcp_project
  gcp_region           = var.gcp_region_europe_west
  gcp_zone             = var.gcp_zone_europe_west
  environment          = var.environment
  commit_sha           = var.commit_sha
  build_number         = var.build_number
  service_name         = var.service_name
  service_name_short   = var.service_name_short
  function_runtime     = var.function_runtime
  container_registry   = var.container_registry
  container_repository = var.container_repository
  fortune_service_account_email = google_service_account.api_account.email
  api_service_account_email = google_service_account.fortune_account.email
  depends_on = [
    google_project_service.iam_api,
    google_project_service.cloudfunctions_api,
    google_project_service.cloudrun_api,
    google_project_service.artifactregistry_api,
    google_project_service.cloudbuild_api,
    google_project_service.cloudtrace_api,
  ]
}
