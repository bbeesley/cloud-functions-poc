locals {
  fortune_component_name     = "fortune"
  fortune_base_name          = "${var.service_name_short}-${local.fortune_component_name}"
  fortune_namespaced_name    = "${local.fortune_base_name}-${var.environment}"
  fortune_container_image    = "${var.container_registry}/${var.gcp_project}/${var.container_repository}/${local.fortune_base_name}-nodejs:${var.commit_sha}"
  fortune_service_account_id = "${local.fortune_base_name}-sc-${var.environment}"
  fortune_env_vars = merge(local.default_environment_variables, {
    SERVICE_NAME = local.fortune_namespaced_name
  })
}

resource "google_service_account" "fortune_account" {
  account_id   = local.fortune_service_account_id
  display_name = "Service account for the fortune api"
  depends_on = [
    google_project_service.iam_api,
  ]
}

resource "google_cloud_run_service" "fortune" {
  name     = local.fortune_namespaced_name
  location = var.gcp_region

  metadata {
    annotations = {
      "run.googleapis.com/client-name" = "terraform"
      "run.googleapis.com/ingress"     = "internal-and-cloud-load-balancing"
    }
  }

  template {
    spec {
      containers {
        image = local.fortune_container_image
        dynamic "env" {
          for_each = local.fortune_env_vars
          content {
            name  = env.key
            value = env.value
          }
        }
      }
    }
  }
  depends_on = [
    google_project_service.cloudrun_api,
  ]
}

data "google_iam_policy" "fortune_noauth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_service_iam_policy" "fortune_noauth" {
  location = google_cloud_run_service.fortune.location
  project  = google_cloud_run_service.fortune.project
  service  = google_cloud_run_service.fortune.name

  policy_data = data.google_iam_policy.fortune_noauth.policy_data
}

resource "google_compute_region_network_endpoint_group" "fortune_neg" {
  name                  = "${local.fortune_base_name}-neg-${var.environment}"
  network_endpoint_type = "SERVERLESS"
  region                = var.gcp_region
  cloud_run {
    service = google_cloud_run_service.fortune.name
  }
}
