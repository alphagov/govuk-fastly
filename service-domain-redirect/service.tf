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
  }

  vcl {
    main    = true
    name    = "main"
    content = file("${path.module}/servicegovuk.vcl")
  }
}
