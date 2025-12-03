resource "fastly_tls_subscription" "domain" {
  for_each              = toset(var.tls_subscription_domains)
  certificate_authority = "globalsign"
  domains               = [each.value]
  configuration_id      = "Ne2ZLbXRrVESyOHMssKP3A" # www-gov-uk.map.fastly.net
}

import {
  for_each = var.tls_subscription_domain_imports
  id       = each.value
  to       = fastly_tls_subscription.domain[each.key]
}