output "tls_subscription_acme_challenges" {
  value = {
    for domain, subscription in fastly_tls_subscription.domain :
    domain => subscription.managed_dns_challenges
  }
}