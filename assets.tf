variable "assets_integration" {
  type = string
}

module "assets-integration" {
  source = "./modules/assets"

  configuration = {
    environment = "integration"
    git_hash    = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
    probe       = "/"
  }

  secrets = yamldecode(var.assets_integration)

  dictionaries = local.dictionaries
}

variable "assets_staging" {
  type = string
}

module "assets-staging" {
  source = "./modules/assets"

  configuration = {
    environment = "staging"
    git_hash    = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
    probe       = "/"
  }

  secrets = yamldecode(var.assets_staging)

  dictionaries = local.dictionaries
}

variable "assets_production" {
  type = string
}

module "assets-production" {
  source = "./modules/assets"

  configuration = {
    environment = "production"
    git_hash    = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
    probe       = "/"
  }

  secrets = yamldecode(var.assets_production)

  dictionaries = local.dictionaries
}
