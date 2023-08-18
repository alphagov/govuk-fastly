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

variable "TFC_RUN_ID" {
  type = string
  default = "unknown"
  description = "Terraform Cloud run ID (automatically populated)"
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
