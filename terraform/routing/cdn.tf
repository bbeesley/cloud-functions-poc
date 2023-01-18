resource "google_compute_managed_ssl_certificate" "lb_default" {
  name = "${var.service_name_short}-ssl-cert-${var.environment}"

  managed {
    domains = [var.domain_name]
  }
}

resource "google_compute_url_map" "lb_default" {
  name            = "${var.service_name_short}-url-map-${var.environment}"
  description     = "Routing table for ${var.service_name}"
  default_service = google_compute_backend_service.api.id

  host_rule {
    hosts        = ["poc.beesley.app"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.api.id
    path_rule {
      paths   = ["/api"]
      service = google_compute_backend_service.api.id
    }
    path_rule {
      paths   = ["/fortune"]
      service = google_compute_backend_service.fortune.id
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

data "google_compute_region_network_endpoint_group" "api" {
  for_each = toset(var.run_regions)
  name     = "${var.service_name_short}-neg-${var.environment}"
  region   = each.value
  depends_on = [
    google_project_service.compute_api,
  ]
}

resource "google_compute_backend_service" "api" {
  name                  = "${var.service_name_short}-backend-${var.environment}"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"

  dynamic "backend" {
    for_each = toset([for o in data.google_compute_region_network_endpoint_group.api : o.id])
    content {
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 0.85
      group           = backend.value
    }
  }
  enable_cdn = true
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    default_ttl       = 3600
    client_ttl        = 7200
    max_ttl           = 10800
    serve_while_stale = true
    negative_caching  = true
    negative_caching_policy {
      code = 404
      ttl  = 1800
    }
    signed_url_cache_max_age_sec = 7200
  }

  # Use an explicit depends_on clause to wait until API is enabled
  depends_on = [
    google_project_service.compute_api,
  ]
}

data "google_compute_region_network_endpoint_group" "fortune" {
  for_each = toset(var.run_regions)
  name     = "${var.service_name_short}-fortune-neg-${var.environment}"
  region   = each.value
  depends_on = [
    google_project_service.compute_api,
  ]
}

resource "google_compute_backend_service" "fortune" {
  name                  = "${var.service_name_short}-fortune-backend-${var.environment}"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"

  dynamic "backend" {
    for_each = toset([for o in data.google_compute_region_network_endpoint_group.fortune : o.id])
    content {
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 0.85
      group           = backend.value
    }
  }
  enable_cdn = true
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    default_ttl       = 60
    client_ttl        = 7200
    max_ttl           = 10800
    serve_while_stale = true
    negative_caching  = true
    negative_caching_policy {
      code = 404
      ttl  = 1800
    }
    signed_url_cache_max_age_sec = 7200
  }

  # Use an explicit depends_on clause to wait until API is enabled
  depends_on = [
    google_project_service.compute_api,
  ]
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
