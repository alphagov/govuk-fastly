variable "environment" {
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

variable "tls_subscription_domains" {
  type    = list(string)
  default = []
}

variable "tls_subscription_domain_imports" {
  type    = map(string)
  default = {}
}
