terraform {
  required_providers {
    fastly = {
      source = "fastly/fastly"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }
  }
}
