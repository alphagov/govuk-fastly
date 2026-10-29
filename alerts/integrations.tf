resource "fastly_integration" "platform_support_slack" {
  name        = "GOV.UK Platform Support - Slack"
  type        = "slack"
  description = "Sends Fastly alerts to GOV.UK Platform Support in Slack"

  config = {
    webhook = var.platform_support_slack_webhook_url
  }
}
