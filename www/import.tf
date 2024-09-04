data "fastly_services" "services" {}

locals {
  fastly_service    = one([for service in data.fastly_services.services.details : service if service.name == "${title(var.environment)} GOV.UK"])
  fastly_service_id = local.fastly_service.id
}

data "fastly_dictionaries" "dicts" {
  service_id      = local.fastly_service_id
  service_version = local.fastly_service.version
}

import {
  to = fastly_service_vcl.service
  id = local.fastly_service_id
}

import {
  for_each = local.dictionaries
  to       = fastly_service_dictionary_items.items[each.key]
  id       = "${local.fastly_service_id}/${one([for d in data.fastly_dictionaries.dicts.dictionaries : d if d.name == each.key]).id}"
}
