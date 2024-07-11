terraform {
  cloud {
    organization = "govuk"
    workspaces {
      name = "govuk-fastly"
    }
  }
  required_version = "~> 1.7"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "5.11.0"
    }
  }
}

provider "fastly" {}

locals {
  dictionaries = merge(
    yamldecode(file("${path.module}/dictionaries.yaml")),
    yamldecode(var.dictionaries)
  )
}
