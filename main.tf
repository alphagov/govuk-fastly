terraform {
  cloud {
    organization = "govuk"
    workspaces {
      name = "govuk-fastly"
    }
  }
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "5.3.1"
    }
  }
}

provider "fastly" {}

variable "TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA" {
  type        = string
  default     = "unknown"
  description = "Git commit hash (automatically populated)"
}

variable "dictionaries" {
  type = string
}

locals {
  dictionaries = merge(
    yamldecode(file("${path.module}/dictionaries.yaml")),
    yamldecode(var.dictionaries)
  )
}
