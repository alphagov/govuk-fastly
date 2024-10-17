import {
  to = aws_s3_bucket.fastly_logs
  id = "govuk-staging-fastly-logs"
}

import {
  to = aws_s3_bucket_logging.fastly_logs
  id = "govuk-staging-fastly-logs"
}

import {
  to = aws_s3_bucket_lifecycle_configuration.fastly_logs
  id = "govuk-staging-fastly-logs"
}

import {
  to = aws_s3_bucket.fastly_logs_monitoring
  id = "govuk-staging-fastly-logs-monitoring"
}

import {
  to = aws_s3_bucket_logging.fastly_logs_monitoring
  id = "govuk-staging-fastly-logs-monitoring"
}

import {
  to = aws_s3_bucket_lifecycle_configuration.fastly_logs_monitoring
  id = "govuk-staging-fastly-logs-monitoring"
}

import {
  to = aws_s3_bucket.transition_fastly_logs
  id = "govuk-staging-transition-fastly-logs"
}

import {
  to = aws_s3_bucket_logging.transition_fastly_logs
  id = "govuk-staging-transition-fastly-logs"
}

import {
  to = aws_s3_bucket_lifecycle_configuration.transition_fastly_logs
  id = "govuk-staging-transition-fastly-logs"
}

import {
  to = aws_iam_user.logs_writer
  id = "govuk-staging-fastly-logs-writer"
}

import {
  to = aws_iam_policy.logs_writer
  id = "arn:aws:iam::172025368201:policy/fastly-logs-staging-logs-writer-policy"
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
  id = "AWSGlueServiceRole-fastly-logs:govuk-staging-fastly-logs-glue-policy"
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
  id = "govuk-staging-transition-downloader"
}

import {
  to = aws_iam_policy.transition_downloader
  id = "arn:aws:iam::172025368201:policy/fastly-logs-staging-transition-downloader-policy"
}

import {
  to = aws_iam_role.transition_executor
  id = "AWSLambdaRole-transition-executor"
}

import {
  to = aws_iam_policy.transition_executor
  id = "arn:aws:iam::172025368201:policy/fastly-logs-staging-transition-executor-policy"
}

import {
  to = aws_iam_role_policy_attachment.transition_executor
  id = "AWSLambdaRole-transition-executor/arn:aws:iam::172025368201:policy/fastly-logs-staging-transition-executor-policy"
}

import {
  to = aws_athena_named_query.transition_logs
  id = "511d805e-7013-4305-b592-41f0bd370b9c"
}

import {
  to = aws_lambda_function.transition_executor
  id = "govuk-staging-transition"
}

import {
  to = aws_cloudwatch_event_rule.transition_executor_daily
  id = "transition_executor_daily"
}

import {
  to = aws_cloudwatch_event_target.transition_executor_daily
  id = "transition_executor_daily/terraform-20190426115748465800000002"
}

import {
  to = aws_lambda_permission.cloudwatch_transition_executor_daily_permission
  id = "govuk-staging-transition/AllowExecutionFromCloudWatch"
}
