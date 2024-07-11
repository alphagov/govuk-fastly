variable "bouncer_production" {
  type = string
}

module "bouncer-production" {
  source = "./modules/bouncer"

  environment = "production"
  domain      = "publishing.service.gov.uk"

  secrets = yamldecode(var.bouncer_production)
}
