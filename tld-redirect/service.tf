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
    bot_management {
      contentguard = "on"
      enabled      = true
    }
    ddos_protection {
      enabled = true
      mode    = "log"
    }
    ngwaf {
      enabled      = true
      traffic_ramp = 100
      workspace_id = "prod"
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
