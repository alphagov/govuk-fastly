terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "tld-redirect"]
    }
  }
  required_version = "~> 1.14"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "8.6.0"
    }
  }
}

provider "fastly" {}
