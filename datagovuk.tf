variable "datagovuk_integration" {
  type = string
}

module "datagovuk-integration" {
  source = "./modules/datagovuk"

  configuration = {
    environment = "integration"
    git_hash = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
    probe = "/"
  }

  secrets = yamldecode(var.datagovuk_integration)
}

variable "datagovuk_staging" {
  type = string
}

module "datagovuk-staging" {
  source = "./modules/datagovuk"

  configuration = {
    environment = "staging"
    git_hash = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
    probe = "/"
  }

  secrets = yamldecode(var.datagovuk_staging)
}

variable "datagovuk_production" {
  type = string
}