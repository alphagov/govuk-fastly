variable "vcl_template_file" {
  type        = string
  default     = "bouncer.vcl.tftpl"
  description = "Relateive path to VCL template"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "domain" {
  type    = string
  default = "publishing.service.gov.uk"
}

variable "secrets" {}
