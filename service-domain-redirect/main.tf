terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "service-domain-redirect"]
    }
  }
  required_version = "~> 1.7"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "8.5.0"
    }
  }
}

provider "fastly" {}
