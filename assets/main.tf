terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "assets"]
    }
  }

  required_version = "~> 1.14"

  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "9.1.0"
    }
  }
}

provider "fastly" {}
