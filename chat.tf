module "chat-integration" {
  source = "./modules/chat"

  configuration = {
    environment     = "integration"
    git_hash        = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
    probe           = "/"
    disable_service = false
  }

  secrets = yamldecode(var.chat_integration)

  dictionaries = local.dictionaries
}

module "chat-staging" {
  source = "./modules/chat"

  configuration = {
    environment     = "staging"
    git_hash        = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
    probe           = "/"
    disable_service = false
  }

  secrets = yamldecode(var.chat_staging)

  dictionaries = local.dictionaries
}

module "chat-production" {
  source = "./modules/chat"

  configuration = {
    environment     = "production"
    git_hash        = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
    probe           = "/"
    disable_service = false
  }

  secrets = yamldecode(var.chat_production)

  dictionaries = local.dictionaries
}
