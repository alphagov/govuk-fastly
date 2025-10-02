terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "assets"]
    }
  }
  required_version = "~> 1.7"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "8.3.0"
    }
  }
}

provider "fastly" {}
