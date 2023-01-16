variable "artifact_bucket_name" {
  description = "The GCS bucket where fn artifacts are stored"
  type        = string
  default     = "deployments-poc-cloud-functions-artifacts"
}

locals {
  service_account_id = "${var.service_name_short}-api-sc-${var.environment}"
  api_function_name  = "${var.service_name_short}-api-${var.environment}"
  api_fn_object_name = "sc/${var.service_name}/api-${var.commit_sha}.zip"
  api_env_vars = merge(local.default_environment_variables, {
    FUNCTION_NAME = local.api_function_name
  })
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

resource "google_service_account" "account" {
  account_id   = local.service_account_id
  display_name = "Service account for the cloud fn api"
  depends_on = [
    google_project_service.iam_api,
  ]
}

resource "google_cloudfunctions2_function" "function" {
  name        = local.api_function_name
  location    = var.gcp_region
  description = "Handles main api responses"

  build_config {
    runtime     = var.function_runtime
    entry_point = "handler"
    source {
      storage_source {
        bucket = var.artifact_bucket_name
        object = local.api_fn_object_name
      }
    }
  }

  service_config {
    max_instance_count               = 3
    min_instance_count               = 1
    available_memory                 = "256M"
    timeout_seconds                  = 60
    max_instance_request_concurrency = 80
    available_cpu                    = "1"
    environment_variables            = local.api_env_vars
    ingress_settings                 = "ALLOW_INTERNAL_AND_GCLB"
    all_traffic_on_latest_revision   = true
    service_account_email            = google_service_account.account.email
  }
  depends_on = [
    google_project_service.cloudfunctions_api,
    google_project_service.artifactregistry_api,
    google_project_service.cloudbuild_api,
  ]
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = var.gcp_region
  service  = local.api_function_name
  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_compute_region_network_endpoint_group" "function_neg" {
  name                  = "${var.service_name_short}-neg-${var.environment}"
  network_endpoint_type = "SERVERLESS"
  region                = var.gcp_region
  cloud_run {
    service = google_cloudfunctions2_function.function.name
  }
}
