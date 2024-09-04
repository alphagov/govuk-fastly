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
  default = "assets.vcl.tftpl"
}
