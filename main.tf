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

locals {
  dictionaries = merge(
    yamldecode(file("${path.module}/dictionaries.yaml")),
    yamldecode(var.dictionaries)
  )
}
