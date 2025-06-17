data "aws_caller_identity" "current" {}

data "tfe_outputs" "logging" {
  organization = "govuk"
  workspace    = "logging-${var.govuk_environment}"
}
