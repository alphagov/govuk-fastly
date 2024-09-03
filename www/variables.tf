variable "govuk_environment" {
  type = string
}

variable "secrets" {
  default = {}
}

variable "configuration" {
  default = {}
}

variable "dictionaries" {
  default = {}
}

variable "vcl_template_file" {
  type    = string
  default = "www.vcl.tftpl"
}

variable "TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA" {
  type    = string
  default = "NO HASH"
}
