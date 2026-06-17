terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "datagovuk"]
    }
  }
  required_version = "~> 1.15"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "9.3.0"
    }
  }
}

provider "fastly" {}
