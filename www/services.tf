resource "fastly_tls_subscription" "domain" {
  for_each = toset(var.tls_subscription_domains)
  certificate_authority = "globalsign"
  domains = each.value
  configuration_id = "Ne2ZLbXRrVESyOHMssKP3A" # www-gov-uk.map.fastly.net
}