locals {
  ab_tests = yamldecode(file("${path.module}/ab_tests.yaml"))
}

variable "www_integration" {
  type = string
}

module "www-integration" {
  source = "./modules/www"

  configuration = {
    environment = "integration"
    run_id = var.TFC_RUN_ID
    probe = "/"
    ab_tests = local.ab_tests
  }

  secrets = yamldecode(var.www_integration)

  dictionaries = local.dictionaries
}

variable "www_staging" {
  type = string
}

module "www-staging" {
  source = "./modules/www"

  configuration = {
    environment = "staging"
    run_id = var.TFC_RUN_ID
    probe = "/"
    ab_tests = local.ab_tests
  }

  secrets = yamldecode(var.www_staging)

  dictionaries = local.dictionaries
}

variable "www_production" {
  type = string
}

module "www-production" {
  source = "./modules/www"

  configuration = {
    environment = "production"
    run_id = var.TFC_RUN_ID
    probe = "/"
    ab_tests = local.ab_tests
  }

  secrets = yamldecode(var.www_production)

  dictionaries = local.dictionaries
}
