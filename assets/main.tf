terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "assets"]
    }
  }

  required_version = "~> 1.15"

  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "9.2.0"
    }
  }
}

provider "fastly" {}
