locals {
  secrets      = yamldecode(var.secrets)
  dictionaries = yamldecode(var.dictionaries)

  ip_allowlist = try(local.secrets["allowed_ip_addresses"], [])
  allowed_cidrs = [
    for v in local.ip_allowlist : strcontains(v, "/") ? v : "${v}/32"
  ]
  formatted_allowed_ips = [
    for v in local.allowed_cidrs : format("\"%s\"/%s", split("/", v)[0], split("/", v)[1])
  ]
  template_values = merge(
    { # some defaults
      origin_port          = 443
      minimum_tls_version  = "1.2"
      ssl_ciphers          = "ECDHE-RSA-AES256-GCM-SHA384"
      basic_authentication = null
      probe_dns_only       = true

      # these values are needed even if mirrors aren't enabled in an environment
      s3_mirror_hostname         = null
      s3_mirror_prefix           = null
      s3_mirror_probe            = null
      s3_mirror_port             = 443
      s3_mirror_replica_hostname = null
      s3_mirror_replica_prefix   = null
      s3_mirror_replica_probe    = null
      s3_mirror_replica_port     = 443
      gcs_mirror_hostname        = null
      gcs_mirror_access_id       = null
      gcs_mirror_secret_key      = null
      gcs_mirror_bucket_name     = null
      gcs_mirror_prefix          = null
      gcs_mirror_probe           = null
      gcs_mirror_port            = 443

      private_extra_vcl_recv = ""

      environment = var.environment
    },
    { # computed values
      formatted_allowed_ip_addresses = local.formatted_allowed_ips
      module_path                    = path.module
    },
    var.configuration,
    local.secrets
  )
}

resource "fastly_service_vcl" "service" {
  name    = "${title(local.template_values["environment"])} data.gov.uk"
  comment = ""

  dynamic "domain" {
    for_each = lookup(local.template_values, "hostnames", [])
    iterator = each
    content {
      name = each.value
    }
  }

  product_enablement {
    ddos_protection {
      enabled = true
      mode    = "block"
    }
    domain_inspector      = true
    log_explorer_insights = true
    origin_inspector      = true
  }

  vcl {
    main    = true
    name    = "main"
    content = templatefile("${path.module}/${var.vcl_template_file}", local.template_values)
  }

  dynamic "dictionary" {
    for_each = local.dictionaries
    content { name = dictionary.key }
  }

  dynamic "condition" {
    for_each = {
      for c in lookup(local.template_values, "conditions", []) : c.name => c
    }
    iterator = each
    content {
      name      = each.key
      priority  = each.value.priority
      statement = each.value.statement
      type      = each.value.type
    }
  }

  dynamic "header" {
    for_each = {
      for c in lookup(local.template_values, "headers", []) : c.name => c
    }
    iterator = each
    content {
      name               = each.key
      action             = each.value.action
      type               = each.value.type
      destination        = each.value.destination
      source             = each.value.source
      response_condition = each.value.response_condition
    }
  }

  dynamic "response_object" {
    for_each = {
      for c in lookup(local.template_values, "response_objects", []) : c.name => c
    }
    iterator = each
    content {
      name              = each.key
      status            = each.value.status
      request_condition = each.value.request_condition

    }
  }

  request_setting {
    name      = "Force TLS"
    force_ssl = true
  }

  rate_limiter {
    name = "rate_limiter_dgu_${local.template_values["environment"]}"

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

  dynamic "logging_splunk" {
    for_each = {
      for splunk in lookup(local.secrets, "splunk", []) : splunk.name => splunk
    }
    iterator = each
    content {
      name           = "Splunk"
      format_version = 2
      format = lookup(each.value, "format", chomp(
        <<-EOT
        {
          "time": %%{time.start.sec}V,
          "host": "Fastly",
          "index": "${each.value.index}",
          "source": "%%{server.region}V:%%{server.datacenter}V:%%{server.hostname}V",
          "sourcetype": "csv:govukcdn_extended",
          "event": "%h %t \\"%r\\" %>s %b \\"%%{Content-Type}o\\" \\"%%{User-Agent}i\\" \\"%%{Referer}i\\" \\"%%{X-Forwarded-For}i\\" \\"%%{Accept}i\\" %%{fastly_info.state}V"
        }
        EOT
      ))
      tls_hostname       = each.value.hostname
      token              = each.value.token
      url                = each.value.url
      use_tls            = true
      response_condition = lookup(each.value, "response_condition", null)
    }
  }

  dynamic "logging_s3" {
    for_each = {
      for s3 in lookup(local.secrets, "s3", []) : s3.name => s3
    }
    iterator = each
    content {
      name               = each.key
      bucket_name        = each.value.bucket_name
      domain             = each.value.domain
      path               = each.value.path
      period             = each.value.period
      redundancy         = each.value.redundancy
      s3_iam_role        = try(each.value.iam_role_arn, null)
      s3_access_key      = try(each.value.access_key_id, null)
      s3_secret_key      = try(each.value.secret_access_key, null)
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

resource "fastly_service_dictionary_items" "items" {
  for_each = {
    for d in fastly_service_vcl.service.dictionary : d.name => d
  }
  service_id    = fastly_service_vcl.service.id
  dictionary_id = each.value.dictionary_id
  items         = local.dictionaries[each.key]
  manage_items  = true
}
