data "fastly_services" "services" {}

locals {
  fastly_service    = one([for service in data.fastly_services.services.details : service if service.name == "${title(var.environment)} Bouncer"])
  fastly_service_id = local.fastly_service.id
}

import {
  to = fastly_service_vcl.service
  id = local.fastly_service_id
}
