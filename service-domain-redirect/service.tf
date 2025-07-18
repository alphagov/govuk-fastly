resource "fastly_service_vcl" "service" {
  name    = "${title(var.environment)} service domain redirect"
  comment = ""

  domain {
    name = "service.gov.uk"
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
    content = file("${path.module}/servicegovuk.vcl")
  }
}
