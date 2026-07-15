terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "mobile-backend"]
    }
  }
  required_version = "~> 1.15"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "9.3.1"
    }
  }
}

provider "fastly" {}
