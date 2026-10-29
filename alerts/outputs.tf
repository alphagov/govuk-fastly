output "platform_support_slack_integration_id" {
  value       = fastly_integration.platform_support_slack.id
  description = "ID of the GOV.UK Platform Support Slack integration, for use in fastly_alert notifications"
}
