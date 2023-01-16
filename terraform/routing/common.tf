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
  default = ["europe-west2"]
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

resource "google_compute_global_address" "lb_default" {
  name         = "${var.service_name_short}-external-${var.environment}"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

resource "google_compute_managed_ssl_certificate" "lb_default" {
  name = "${var.service_name_short}-ssl-cert-${var.environment}"

  managed {
    domains = [var.domain_name]
  }
}

resource "google_compute_url_map" "lb_default" {
  name            = "${var.service_name_short}-url-map-${var.environment}"
  description     = "Routing table for ${var.service_name}"
  default_service = google_compute_backend_service.lb_default.id

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.lb_default.id
    route_rules {
      priority = 1
      url_redirect {
        https_redirect         = true
        redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
      }
    }
  }
}

resource "google_compute_target_https_proxy" "lb_default" {
  name    = "${var.service_name_short}-lb-${var.environment}"
  url_map = google_compute_url_map.lb_default.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.lb_default.name
  ]
  depends_on = [
    google_compute_managed_ssl_certificate.lb_default
  ]
}

resource "google_compute_global_forwarding_rule" "lb_default" {
  name                  = "${var.service_name_short}-lb-fr-${var.environment}"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_https_proxy.lb_default.id
  ip_address            = google_compute_global_address.lb_default.id
  port_range            = "443"
  depends_on            = [google_compute_target_https_proxy.lb_default]
}

data "google_compute_region_network_endpoint_group" "lb_default" {
  for_each = toset(var.run_regions)
  name     = "${var.service_name_short}-neg-${var.environment}"
  region   = each.value
  depends_on = [
    google_project_service.compute_api,
  ]
}

resource "google_compute_backend_service" "lb_default" {
  name                  = "${var.service_name_short}-backend-${var.environment}"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  dynamic "backend" {
    for_each = toset(var.run_regions)
    content {
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 0.85
      group           = data.google_compute_region_network_endpoint_group.lb_default[backend.value].id
    }
  }

  # Use an explicit depends_on clause to wait until API is enabled
  depends_on = [
    google_project_service.compute_api,
  ]
}

resource "google_dns_record_set" "lb_default" {
  name = var.domain_name
  type = "A"
  ttl  = 300

  managed_zone = var.dns_zone

  rrdatas = [google_compute_global_address.lb_default.self_link]
}

resource "google_compute_url_map" "https_default" {
  name = "${var.service_name_short}-https-url-map-${var.environment}"

  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    https_redirect         = true
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "https_default" {
  name    = "${var.service_name_short}-http-proxy-${var.environment}"
  url_map = google_compute_url_map.https_default.id

  depends_on = [
    google_compute_url_map.https_default
  ]
}

resource "google_compute_global_forwarding_rule" "https_default" {
  name       = "${var.service_name_short}-https-fr-${var.environment}"
  target     = google_compute_target_http_proxy.https_default.id
  ip_address = google_compute_global_address.lb_default.id
  port_range = "80"
  depends_on = [google_compute_target_http_proxy.https_default]
}
