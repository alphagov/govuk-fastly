locals {
  ab_tests = yamldecode(file("${path.module}/ab_tests.yaml"))
}

module "www-staging" {
  source = "./modules/www"

  configuration = {
    environment = "staging"
    git_hash    = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
    probe       = "/"
    ab_tests    = local.ab_tests
  }

  secrets = yamldecode(var.www_staging)

  dictionaries = local.dictionaries
}

module "www-production" {
  source = "./modules/www"

  configuration = {
    environment = "production"
    git_hash    = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
    probe       = "/"
    ab_tests    = local.ab_tests
  }

  secrets = yamldecode(var.www_production)

  dictionaries = local.dictionaries
}
