terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "service-domain-redirect"]
    }
  }
  required_version = "~> 1.14"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "9.1.0"
    }
  }
}

provider "fastly" {}
