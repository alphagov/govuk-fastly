terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "bouncer"]
    }
  }
  required_version = "~> 1.7"
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "5.11.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }
  }
}
provider "fastly" {}

provider "http" {}
