terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "tld-redirect"]
    }
  }
  required_version = "~> 1.7"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "8.0.0"
    }
  }
}

provider "fastly" {}
