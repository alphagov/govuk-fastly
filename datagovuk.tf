variable "datagovuk_integration" {
  type = string
}

# module "datagovuk-integration" {
#   source = "./modules/datagovuk"

#   configuration = {
#     environment = "integration"
#     git_hash = var.TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA
#     probe = "/"
#   }

#   secrets = yamldecode(var.datagovuk_integration)
# }
