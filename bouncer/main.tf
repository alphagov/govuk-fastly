terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "bouncer"]
    }
  }
  required_version = "~> 1.14"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "8.7.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.5.0"
    }
  }
}
provider "fastly" {}

provider "http" {}
