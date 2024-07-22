data "http" "domains" {
  url = "https://transition.publishing.service.gov.uk/hosts.json"
}

locals {
  domains_json = jsondecode(data.http.domains.response_body)
  domains = {
    for d in local.domains_json.results :
    d.hostname => ""
  }
}

resource "fastly_service_vcl" "service" {
  name    = "${title(var.environment)} Bouncer"
  comment = ""

  dynamic "domain" {
    for_each = local.domains
    iterator = each
    content {
      name    = each.key
      comment = ""
    }
  }

  vcl {
    main = true
    name = "main"
    content = templatefile("${path.module}/${var.vcl_template_file}", {
      domain      = var.domain,
      module_path = path.module
    })
  }

  rate_limiter {
    name = "rate_limiter_bouncer"

    rps_limit            = 100
    window_size          = 10
    penalty_box_duration = 5

    client_key   = "req.http.Fastly-Client-IP"
    http_methods = "GET,PUT,TRACE,POST,HEAD,DELETE,PATCH,OPTIONS"

    action = "response"
    response {
      content      = "Too many requests"
      content_type = "plain/text"
      status       = 429
    }
  }

  dynamic "logging_s3" {
    for_each = {
      for s3 in lookup(var.secrets, "s3", []) : s3.name => s3
    }
    iterator = each
    content {
      name               = each.key
      bucket_name        = each.value.bucket_name
      domain             = each.value.domain
      path               = each.value.path
      period             = each.value.period
      redundancy         = each.value.redundancy
      s3_access_key      = each.value.access_key_id
      s3_secret_key      = each.value.secret_access_key
      response_condition = lookup(each.value, "response_condition", null)

      format_version   = 2
      message_type     = "blank"
      gzip_level       = 9
      timestamp_format = "%Y-%m-%dT%H:%M:%S.000"

      format = lookup(each.value, "format", chomp(
        <<-EOT
        { "client_ip":"%%{json.escape(client.ip)}V", "request_received":"%%{begin:%Y-%m-%d %H:%M:%S.}t%%{time.start.msec_frac}V", "request_received_offset":"%%{begin:%z}t", "method":"%%{json.escape(req.method)}V", "url":"%%{json.escape(req.url)}V", "status":%>s, "request_time":%%{time.elapsed.sec}V.%%{time.elapsed.msec_frac}V, "time_to_generate_response":%%{time.to_first_byte}V, "bytes":%B, "content_type":"%%{json.escape(resp.http.Content-Type)}V", "user_agent":"%%{json.escape(req.http.User-Agent)}V", "fastly_backend":"%%{json.escape(resp.http.Fastly-Backend-Name)}V", "data_centre":"%%{json.escape(server.datacenter)}V", "cache_hit":%%{if(fastly_info.state ~"^(HIT|MISS)(?:-|$)", "true", "false")}V, "cache_response":"%%{regsub(fastly_info.state, "^(HIT-(SYNTH)|(HITPASS|HIT|MISS|PASS|ERROR|PIPE)).*", "\\2\\3") }V", "tls_client_protocol":"%%{json.escape(tls.client.protocol)}V", "tls_client_cipher":"%%{json.escape(tls.client.cipher)}V", "client_ja3":"%%{json.escape(req.http.Client-JA3)}V" }
        EOT
      ))
    }
  }
}
