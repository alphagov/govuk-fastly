terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["fastly", "logs"]
    }
  }
  required_version = "~> 1.12"
}

provider "aws" {
  region = "eu-west-1"
  default_tags {
    tags = {
      Product              = "GOV.UK"
      System               = "Fastly"
      Environment          = var.govuk_environment
      Owner                = "govuk-platform-engineering@digital.cabinet-office.gov.uk"
      repository           = "govuk-fastly"
      terraform_deployment = basename(abspath(path.root))
    }
  }
}

provider "archive" {}

provider "tfe" {}
