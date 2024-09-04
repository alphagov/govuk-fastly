resource "fastly_service_vcl" "service" {
  name    = "${title(var.environment)} TLD Redirect"
  comment = ""

  domain {
    name = "gov.uk"
  }

  vcl {
    main    = true
    name    = "main"
    content = file("${path.module}/tldredirect.vcl")
  }
}
