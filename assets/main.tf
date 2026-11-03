terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "assets"]
    }
  }

  required_version = "~> 1.17"

  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "10.0.0"
    }
  }
}

provider "fastly" {}
