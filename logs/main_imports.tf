import {
  to = aws_s3_bucket.fastly_logs
  id = "govuk-production-fastly-logs"
}

import {
  to = aws_s3_bucket_logging.fastly_logs
  id = "govuk-production-fastly-logs"
}

import {
  to = aws_s3_bucket_lifecycle_configuration.fastly_logs
  id = "govuk-production-fastly-logs"
}

import {
  to = aws_s3_bucket.fastly_logs_monitoring
  id = "govuk-production-fastly-logs-monitoring"
}

import {
  to = aws_s3_bucket_logging.fastly_logs_monitoring
  id = "govuk-production-fastly-logs-monitoring"
}

import {
  to = aws_s3_bucket_lifecycle_configuration.fastly_logs_monitoring
  id = "govuk-production-fastly-logs-monitoring"
}

import {
  to = aws_s3_bucket.transition_fastly_logs
  id = "govuk-production-transition-fastly-logs"
}

import {
  to = aws_s3_bucket_logging.transition_fastly_logs
  id = "govuk-production-transition-fastly-logs"
}

import {
  to = aws_s3_bucket_lifecycle_configuration.transition_fastly_logs
  id = "govuk-production-transition-fastly-logs"
}

import {
  to = aws_iam_user.logs_writer
  id = "govuk-production-fastly-logs-writer"
}

import {
  to = aws_iam_policy.logs_writer
  id = "arn:aws:iam::172025368201:policy/fastly-logs-production-logs-writer-policy"
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
  id = "AWSGlueServiceRole-fastly-logs:govuk-production-fastly-logs-glue-policy"
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
  id = "govuk-production-transition-downloader"
}

import {
  to = aws_iam_policy.transition_downloader
  id = "arn:aws:iam::172025368201:policy/fastly-logs-production-transition-downloader-policy"
}

import {
  to = aws_iam_role.transition_executor
  id = "AWSLambdaRole-transition-executor"
}

import {
  to = aws_iam_policy.transition_executor
  id = "arn:aws:iam::172025368201:policy/fastly-logs-production-transition-executor-policy"
}

import {
  to = aws_iam_role_policy_attachment.transition_executor
  id = "AWSLambdaRole-transition-executor/arn:aws:iam::172025368201:policy/fastly-logs-production-transition-executor-policy"
}

import {
  to = aws_athena_named_query.transition_logs
  id = "b475cbb1-0212-4192-a6db-de83b400ee00"
}

import {
  to = aws_lambda_function.transition_executor
  id = "govuk-production-transition"
}

import {
  to = aws_cloudwatch_event_rule.transition_executor_daily
  id = "transition_executor_daily"
}

import {
  to = aws_cloudwatch_event_target.transition_executor_daily
  id = "transition_executor_daily/terraform-20180907135027830200000002"
}

import {
  to = aws_lambda_permission.cloudwatch_transition_executor_daily_permission
  id = "govuk-production-transition/AllowExecutionFromCloudWatch"
}
