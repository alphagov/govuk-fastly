import {
  to = aws_s3_bucket.fastly_logs
  id = "govuk-integration-fastly-logs"
}

import {
  to = aws_s3_bucket_logging.fastly_logs
  id = "govuk-integration-fastly-logs"
}

import {
  to = aws_s3_bucket_lifecycle_configuration.fastly_logs
  id = "govuk-integration-fastly-logs"
}

import {
  to = aws_s3_bucket.fastly_logs_monitoring
  id = "govuk-integration-fastly-logs-monitoring"
}

import {
  to = aws_s3_bucket_logging.fastly_logs_monitoring
  id = "govuk-integration-fastly-logs-monitoring"
}

import {
  to = aws_s3_bucket_lifecycle_configuration.fastly_logs_monitoring
  id = "govuk-integration-fastly-logs-monitoring"
}

import {
  to = aws_s3_bucket.transition_fastly_logs
  id = "govuk-integration-transition-fastly-logs"
}

import {
  to = aws_s3_bucket_logging.transition_fastly_logs
  id = "govuk-integration-transition-fastly-logs"
}

import {
  to = aws_s3_bucket_lifecycle_configuration.transition_fastly_logs
  id = "govuk-integration-transition-fastly-logs"
}

import {
  to = aws_iam_user.logs_writer
  id = "govuk-integration-fastly-logs-writer"
}

import {
  to = aws_iam_policy.logs_writer
  id = "arn:aws:iam::172025368201:policy/fastly-logs-integration-logs-writer-policy"
}

import {
  to = aws_glue_catalog_database.fastly_logs
  id = "172025368201:fastly_logs"
}

import {
  to = aws_iam_role_policy_attachment.aws-glue-service-role-service-attachment
  id = "AWSGlueServiceRole-fastly-logs/arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

import {
  to = aws_iam_role.glue
  id = "AWSGlueServiceRole-fastly-logs"
}

import {
  to = aws_iam_role_policy.fastly_logs_policy
  id = "AWSGlueServiceRole-fastly-logs:govuk-integration-fastly-logs-glue-policy"
}

import {
  to = aws_glue_crawler.govuk_www
  id = "GOV.UK fastly logs"
}

import {
  to = aws_glue_catalog_table.govuk_www
  id = "172025368201:fastly_logs:govuk_www"
}

import {
  to = aws_glue_crawler.govuk_assets
  id = "Assets fastly logs"
}

import {
  id = "172025368201:fastly_logs:govuk_assets"
  to = aws_glue_catalog_table.govuk_assets
}

import {
  to = aws_glue_crawler.bouncer
  id = "Bouncer fastly logs"
}

import {
  id = "172025368201:fastly_logs:bouncer"
  to = aws_glue_catalog_table.bouncer
}

import {
  to = aws_iam_user.transition_downloader
  id = "govuk-integration-transition-downloader"
}

import {
  to = aws_iam_policy.transition_downloader
  id = "arn:aws:iam::172025368201:policy/fastly-logs-integration-transition-downloader-policy"
}

import {
  to = aws_iam_role.transition_executor
  id = "AWSLambdaRole-transition-executor"
}

import {
  to = aws_iam_policy.transition_executor
  id = "arn:aws:iam::172025368201:policy/fastly-logs-integration-transition-executor-policy"
}

import {
  to = aws_iam_role_policy_attachment.transition_executor
  id = "AWSLambdaRole-transition-executor/arn:aws:iam::172025368201:policy/fastly-logs-integration-transition-executor-policy"
}

import {
  to = aws_athena_named_query.transition_logs
  id = "0ee11316-262c-4dea-8bfe-135a9374b5fc"
}

import {
  to = aws_lambda_function.transition_executor
  id = "govuk-integration-transition"
}

import {
  to = aws_cloudwatch_event_rule.transition_executor_daily
  id = "transition_executor_daily"
}

import {
  to = aws_cloudwatch_event_target.transition_executor_daily
  id = "transition_executor_daily/terraform-20190426121530164600000002"
}

import {
  to = aws_lambda_permission.cloudwatch_transition_executor_daily_permission
  id = "govuk-integration-transition/AllowExecutionFromCloudWatch"
}
