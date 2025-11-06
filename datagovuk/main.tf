terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "datagovuk"]
    }
  }
  required_version = "~> 1.7"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "8.4.0"
    }
  }
}

provider "fastly" {}
