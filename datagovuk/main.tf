terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "datagovuk"]
    }
  }
  required_version = "~> 1.14"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "9.0.0"
    }
  }
}

provider "fastly" {}
