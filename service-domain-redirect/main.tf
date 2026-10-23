terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "service-domain-redirect"]
    }
  }
  required_version = "~> 1.16"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "10.0.0"
    }
  }
}

provider "fastly" {}
