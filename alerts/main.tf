terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "alerts"]
    }
  }

  required_version = "~> 1.16"

  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "9.8.0"
    }
  }
}

provider "fastly" {}
