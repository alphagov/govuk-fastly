resource "fastly_service_vcl" "service" {
  name    = "${title(var.environment)} TLD Redirect"
  comment = ""

  domain {
    name = var.domain
  }

  vcl {
    main    = true
    name    = "main"
    content = templatefile("${path.module}/tldredirect.vcl.tftpl", { domain = var.domain })
  }
}
