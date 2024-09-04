locals {
  strip_headers = [
    "x-amz-id-2",
    "x-amz-meta-server-side-encryption",
    "x-amz-request-id",
    "x-amz-version-id",
    "x-amz-server-side-encryption"
  ]
  # headers to add
  ttl                         = "300s" # 5 minutes
  cache_control               = "max-age=300, public, immutable"
  access_control_allow_origin = "*"
}

resource "fastly_service_vcl" "mobile_backend_service" {
  name  = "GOV.UK App mobile backend - ${title(var.environment)}"
  http3 = true

  domain {
    name = var.hostname
  }

  backend {
    name    = "Mobile backend config bucket - ${var.environment}"
    address = var.origin_hostname
    port    = 443

    connect_timeout       = 1000
    first_byte_timeout    = 15000
    max_conn              = 200
    between_bytes_timeout = 10000

    ssl_check_cert    = true
    ssl_ciphers       = "ECDHE-RSA-AES256-GCM-SHA384"
    ssl_cert_hostname = var.origin_hostname
    ssl_sni_hostname  = var.origin_hostname
    min_tls_version   = "1.2"
  }

  dynamic "header" {
    for_each = local.strip_headers
    content {
      destination = "http.${header.value}"
      name        = "Remove ${header.value}"
      action      = "delete"
      type        = "cache"
    }
  }

  header {
    destination = "ttl"
    name        = "Add ttl header"
    action      = "set"
    type        = "response"
    source      = local.ttl
  }

  header {
    destination = "http.Cache-Control"
    name        = "Add Cache-Control header"
    action      = "set"
    type        = "response"
    source      = local.cache_control
  }

  header {
    destination = "http.Access-Control-Allow-Origin"
    name        = "Add Access-Control-Allow-Origin header"
    action      = "set"
    type        = "response"
    source      = local.access_control_allow_origin
  }

}
