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
    git_hash = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
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
    git_hash = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
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
    git_hash = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
    probe = "/"
    ab_tests = local.ab_tests
  }

  secrets = yamldecode(var.www_production)

  dictionaries = local.dictionaries
}
