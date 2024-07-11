variable "assets_integration" {
  type = string
}

variable "assets_staging" {
  type = string
}

variable "assets_production" {
  type = string
}

variable "bouncer_production" {
  type = string
}

variable "datagovuk_integration" {
  type = string
}

variable "datagovuk_staging" {
  type = string
}

variable "datagovuk_production" {
  type = string
}

variable "www_integration" {
  type = string
}

variable "www_staging" {
  type = string
}

variable "www_production" {
  type = string
}

variable "TFC_CONFIGURATION_VERSION_GIT_COMMIT_SHA" {
  type        = string
  default     = "unknown"
  description = "Git commit hash (automatically populated)"
}

variable "dictionaries" {
  type = string
}

