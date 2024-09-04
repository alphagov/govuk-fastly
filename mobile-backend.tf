module "mobile-backend-integration" {
  source = "./modules/mobile-backend"

  environment     = "integration"
  hostname        = "app.integration.govuk.digital"
  origin_hostname = "govuk-app-remote-config-integration.s3.eu-west-1.amazonaws.com"
}

module "mobile-backend-staging" {
  source = "./modules/mobile-backend"

  environment     = "staging"
  hostname        = "app.staging.govuk.digital"
  origin_hostname = "govuk-app-remote-config-staging.s3.eu-west-1.amazonaws.com"
}

module "mobile-backend-production" {
  source = "./modules/mobile-backend"

  environment     = "production"
  hostname        = "app.govuk.digital"
  origin_hostname = "govuk-app-remote-config-production.s3.eu-west-1.amazonaws.com"
}
