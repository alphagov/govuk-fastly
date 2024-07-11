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
