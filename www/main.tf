terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "www"]
    }
  }
  required_version = "~> 1.7"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "5.11.0"
    }
  }
}

provider "fastly" {}