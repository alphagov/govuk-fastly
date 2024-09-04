resource "fastly_service_vcl" "service" {
  name    = "${title(var.environment)} service domain redirect"
  comment = ""

  domain {
    name = "service.gov.uk"
  }

  vcl {
    main    = true
    name    = "main"
    content = file("${path.module}/servicegovuk.vcl")
  }
}
