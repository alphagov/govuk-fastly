terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "mobile-backend"]
    }
  }
  required_version = "~> 1.12"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "8.6.0"
    }
  }
}

provider "fastly" {}
