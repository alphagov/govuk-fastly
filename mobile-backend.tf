module "mobile-backend-integration" {
  source = "./modules/mobile-backend"

  environment     = "integration"
  hostname        = "app.integration.publishing.service.gov.uk"
  origin_hostname = "govuk-app-remote-config-integration.s3.eu-west-1.amazonaws.com"
}
