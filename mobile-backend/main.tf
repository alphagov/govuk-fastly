terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "mobile-backend"]
    }
  }
  required_version = "~> 1.17"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "10.3.0"
    }
  }
}

provider "fastly" {}
