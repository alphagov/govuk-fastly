locals {
  transition_executor_target_ids = {
    integration = "terraform-20190426121530164600000002"
    staging     = "terraform-20190426115748465800000002"
    production  = "terraform-20180907135027830200000002"
  }
}

data "aws_athena_named_query" "transition_logs_import" {
  name = "transition-logs-query"
}

import {
  to = aws_athena_named_query.transition_logs
  id = data.aws_athena_named_query.transition_logs_import.id
}

import {
  to = aws_cloudwatch_event_rule.transition_executor_daily
  id = "transition_executor_daily"
}

import {
  to = aws_cloudwatch_event_target.transition_executor_daily
  id = "${aws_cloudwatch_event_rule.transition_executor_daily.name}/${local.transition_executor_target_ids[var.govuk_environment]}"
}

import {
  to = aws_glue_catalog_database.fastly_logs
  id = "${data.aws_caller_identity.current.account_id}:fastly_logs"
}

# only exists in production
import {
  for_each = { for i in range(1) : "import" => true if var.govuk_environment == "production" }
  to       = aws_glue_catalog_table.bouncer
  id       = "${data.aws_caller_identity.current.account_id}:fastly_logs:bouncer"
}

import {
  to = aws_glue_catalog_table.govuk_www
  id = "${data.aws_caller_identity.current.account_id}:fastly_logs:govuk_www"
}

import {
  to = aws_glue_catalog_table.govuk_assets
  id = "${data.aws_caller_identity.current.account_id}:fastly_logs:govuk_assets"
}

import {
  to = aws_glue_crawler.bouncer
  id = "Bouncer fastly logs"
}

import {
  to = aws_glue_crawler.govuk_www
  id = "GOV.UK fastly logs"
}

import {
  to = aws_glue_crawler.govuk_assets
  id = "Assets fastly logs"
}

import {
  to = aws_lambda_permission.cloudwatch_transition_executor_daily_permission
  id = "${aws_lambda_function.transition_executor.function_name}/AllowExecutionFromCloudWatch"
}

# only exists in integration
import {
  for_each = { for i in range(1) : "import" => true if var.govuk_environment == "integration" }
  to       = aws_iam_user.athena_monitoring
  id       = "govuk-${var.govuk_environment}-fastly-logs-athena-monitoring"
}

# only exists in integration
import {
  for_each = { for i in range(1) : "import" => true if var.govuk_environment == "integration" }
  to       = aws_iam_policy.athena_monitoring
  id       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/fastly-logs-${var.govuk_environment}-fastly-logs-athena-monitoring-policy"
}

# only exists in integration
import {
  for_each = { for i in range(1) : "import" => true if var.govuk_environment == "integration" }
  to       = aws_iam_user_policy_attachment.athena_monitoring
  id       = "${aws_iam_user.athena_monitoring.name}/${aws_iam_policy.athena_monitoring.arn}"
}
