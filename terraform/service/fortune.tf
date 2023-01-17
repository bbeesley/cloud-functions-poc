locals {
  fortune_component_name = "fortune"
  fortune_base_name = "${var.service_name_short}-${local.fortune_component_name}"
  fortune_namespaced_name = "${local.fortune_base_name}-${var.environment}"
  fortune_container_image = "${var.container_registry}/${var.gcp_project}/${var.container_repository}/${local.fortune_base_name}:${var.commit_sha}"
}

resource "google_cloud_run_service" "fortune" {
    name     = local.fortune_namespaced_name
    location = var.gcp_region

    metadata {
      annotations = {
        "run.googleapis.com/client-name" = "terraform"
      }
    }

    template {
      spec {
        containers {
          image = fortune_container_image
        }
      }
    }
 }

 data "google_iam_policy" "noauth" {
   binding {
     role = "roles/run.invoker"
     members = ["allUsers"]
   }
 }

 resource "google_cloud_run_service_iam_policy" "noauth" {
   location    = google_cloud_run_service.fortune.location
   project     = google_cloud_run_service.fortune.project
   service     = google_cloud_run_service.fortune.name

   policy_data = data.google_iam_policy.noauth.policy_data
}