variable "assets_integration" {
  type = string
}

module "assets-integration" {
  source = "./modules/assets"

  configuration = {
    environment = "integration"
    run_id = var.TFC_RUN_ID
    probe = "/"
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
    run_id = var.TFC_RUN_ID
    probe = "/"
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
    run_id = var.TFC_RUN_ID
    probe = "/"
  }

  secrets = yamldecode(var.assets_production)

  dictionaries = local.dictionaries
}
