
resource "google_compute_global_address" "lb_default" {
  name         = "${var.service_name_short}-external-${var.environment}"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}
resource "google_compute_global_address" "anopther" {
  name         = "${var.service_name_short}-another-${var.environment}"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

data "google_compute_global_address" "lb_default" {
  name = "${var.service_name_short}-external-${var.environment}"
  depends_on = [
    google_compute_global_address.lb_default
  ]
}

resource "google_dns_record_set" "lb_default" {
  name = var.domain_name
  type = "A"
  ttl  = 300

  managed_zone = var.dns_zone

  rrdatas = [data.google_compute_global_address.lb_default.address]
}
