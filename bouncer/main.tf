terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "bouncer"]
    }
  }
  required_version = "~> 1.15"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "9.3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.6.0"
    }
  }
}
provider "fastly" {}

provider "http" {}
