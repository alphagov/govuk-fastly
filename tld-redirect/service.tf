locals {
  secrets = yamldecode(var.secrets)
}

resource "fastly_service_vcl" "service" {
  name    = "${title(var.environment)} TLD Redirect"
  comment = ""

  domain {
    name = local.secrets["domain"]
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
    content = templatefile("${path.module}/tldredirect.vcl.tftpl", local.secrets)
  }
}
