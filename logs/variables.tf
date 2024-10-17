variable "environment" {
  type    = string
  default = "production"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-1"
}
