terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "datagovuk"]
    }
  }
  required_version = "~> 1.16"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "9.6.0"
    }
  }
}

provider "fastly" {}
