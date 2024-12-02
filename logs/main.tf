terraform {
  cloud {
    organization = "govuk"
    workspaces {
      tags = ["logs", "fastly"]
    }
  }
  required_version = "~> 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "tfe" {}

provider "archive" {}

resource "aws_s3_bucket" "fastly_logs" {
  bucket = "govuk-${var.environment}-fastly-logs"
}

resource "aws_s3_bucket_logging" "fastly_logs" {
  bucket = aws_s3_bucket.fastly_logs.id

  target_bucket = "govuk-${var.environment}-aws-logging"
  target_prefix = "s3/govuk-${var.environment}-fastly-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "fastly_logs" {
  bucket = aws_s3_bucket.fastly_logs.id

  rule {
    id = "expire"

    status = "Enabled"

    expiration {
      days = 120
    }

    noncurrent_version_expiration {
      noncurrent_days           = 1
      newer_noncurrent_versions = ""
    }
  }
}

# We require a user for Fastly to write to S3 buckets
resource "aws_iam_user" "logs_writer" {
  name = "govuk-${var.environment}-fastly-logs-writer"
}

data "aws_iam_policy_document" "logs_writer_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
    ]
    resources = [
      "arn:aws:s3:::*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.fastly_logs.id}",
      "arn:aws:s3:::${aws_s3_bucket.fastly_logs.id}/*",
    ]
  }
}

resource "aws_iam_policy" "logs_writer" {
  name        = "fastly-logs-${var.environment}-logs-writer-policy"
  policy      = data.aws_iam_policy_document.logs_writer_policy.json
  description = "Allows writing to the fastly-logs bucket"
}

resource "aws_iam_policy_attachment" "logs_writer" {
  name       = "logs-writer-policy-attachment"
  users      = [aws_iam_user.logs_writer.name]
  policy_arn = aws_iam_policy.logs_writer.arn
}

resource "aws_glue_catalog_database" "fastly_logs" {
  name        = "fastly_logs"
  description = "Used to browse the CDN log files that Fastly sends"
}

resource "aws_iam_role_policy_attachment" "aws-glue-service-role-service-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  role       = aws_iam_role.glue.name
}

resource "aws_iam_role" "glue" {
  name = "AWSGlueServiceRole-fastly-logs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "fastly_logs_policy" {
  name = "govuk-${var.environment}-fastly-logs-glue-policy"
  role = aws_iam_role.glue.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.fastly_logs.id}",
        "arn:aws:s3:::${aws_s3_bucket.fastly_logs.id}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_glue_crawler" "govuk_www" {
  name          = "GOV.UK fastly logs"
  description   = "Crawls the GOV.UK logs from fastly for allowing Athena querying"
  database_name = aws_glue_catalog_database.fastly_logs.name
  role          = aws_iam_role.glue.name
  schedule      = "cron(30 */4 * * ? *)"

  s3_target {
    path = "s3://${aws_s3_bucket.fastly_logs.bucket}/govuk_www"
  }

  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
    update_behavior = "LOG"
  }

  configuration = <<EOF
{
  "Version": 1.0,
  "CrawlerOutput": {
    "Partitions": {
      "AddOrUpdateBehavior": "InheritFromTable"
    }
  }
}
EOF
}

resource "aws_glue_catalog_table" "govuk_www" {
  name          = "govuk_www"
  description   = "Allows access to JSON data exported from Fastly"
  database_name = aws_glue_catalog_database.fastly_logs.name
  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    compressed    = true
    location      = "s3://${aws_s3_bucket.fastly_logs.bucket}/govuk_www/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name = "ser_de_name"

      parameters = {
        paths                   = "client_ip,request_received,request_received_offset,method,url,status,protocol,request_time,time_to_generate_response,bytes,content_type,user_agent,fastly_backend,data_centre,cache_hit,cache_response,tls_client_protocol,tls_client_cipher,client_ja3"
        "ignore.malformed.json" = "true"
      }

      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    // These columns correlate with the log format set up in Fastly as below
    //
    // {
    // "client_ip":"%{json.escape(client.ip)}V",
    // "request_received":"%{begin:%Y-%m-%d %H:%M:%S.}t%{time.start.msec_frac}V",
    // "request_received_offset":"%{begin:%z}t",
    // "method":"%{json.escape(req.method)}V",
    // "url":"%{json.escape(req.url)}V",
    // "status":%>s,
    // "protocol":"%{json.escape(req.proto)}V",
    // "request_time":%{time.elapsed.sec}V.%{time.elapsed.msec_frac}V,
    // "time_to_generate_response":%{time.to_first_byte}V,
    // "bytes":%B,
    // "content_type":"%{json.escape(resp.http.Content-Type)}V",
    // "user_agent":"%{json.escape(req.http.User-Agent)}V",
    // "fastly_backend":"%{json.escape(resp.http.Fastly-Backend-Name)}V",
    // "data_centre":"%{json.escape(server.datacenter)}V",
    // "cache_hit":%{if(fastly_info.state ~"^(HIT|MISS)(?:-|$)", "true", "false")}V,
    // "cache_response":"%{regsub(fastly_info.state, "^(HIT-(SYNTH)|(HITPASS|HIT|MISS|PASS|ERROR|PIPE)).*", "\\2\\3") }V",
    // "tls_client_protocol":"%{json.escape(tls.client.protocol)}V",
    // "tls_client_cipher":"%{json.escape(tls.client.cipher)}V",
    // "client_ja3":"%{json.escape(req.http.Client-JA3)}V"
    // }
    columns {
      name    = "client_ip"
      type    = "string"
      comment = "IP address of the client that made the request"
    }
    columns {
      name    = "request_received"
      type    = "timestamp"
      comment = "Time we received the request"
    }
    columns {
      // This field is separate from the timestamp above as the Presto version
      // on AWS Athena doesn't support timestamps - expectation is that this is
      // always +0000 though
      name = "request_received_offset"

      type    = "string"
      comment = "Time offset of the request, expected to be +0000 always"
    }
    columns {
      name    = "method"
      type    = "string"
      comment = "HTTP method for this request"
    }
    columns {
      name    = "url"
      type    = "string"
      comment = "URL requested with query string"
    }
    columns {
      name    = "status"
      type    = "int"
      comment = "HTTP status code returned"
    }
    columns {
      name    = "request_time"
      type    = "double"
      comment = "Time until user received full response in seconds"
    }
    columns {
      name    = "time_to_generate_response"
      type    = "double"
      comment = "Time spent generating a response for varnish, in seconds"
    }
    columns {
      name    = "bytes"
      type    = "bigint"
      comment = "Number of bytes returned"
    }
    columns {
      name    = "content_type"
      type    = "string"
      comment = "HTTP Content-Type header returned"
    }
    columns {
      name    = "user_agent"
      type    = "string"
      comment = "User agent that made the request"
    }
    columns {
      name    = "fastly_backend"
      type    = "string"
      comment = "Name of the backend that served this request"
    }
    columns {
      name    = "data_centre"
      type    = "string"
      comment = "Name of the data centre that served this request"
    }
    columns {
      name    = "cache_hit"
      type    = "boolean"
      comment = "Whether this object is cacheable or not"
    }
    columns {
      name    = "cache_response"
      type    = "string"
      comment = "Whether the response was a HIT, MISS, PASS, ERROR, PIPE, HITPASS, or SYNTH(etic)"
    }
    columns {
      name = "tls_client_protocol"
      type = "string"
    }
    columns {
      name = "tls_client_cipher"
      type = "string"
    }
    columns {
      name = "client_ja3"
      type = "string"
    }
    columns {
      name    = "protocol"
      type    = "string"
      comment = "HTTP version used"
    }
  }

  // these correspond to directory ordering of:
  // /year=YYYY/month=MM/date=DD/file.log.gz
  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "date"
    type = "int"
  }

  parameters = {
    classification  = "json"
    compressionType = "gzip"
    typeOfDate      = "file"
  }
}

resource "aws_glue_crawler" "govuk_assets" {
  name          = "Assets fastly logs"
  description   = "Crawls the assets logs from fastly for allowing Athena querying"
  database_name = aws_glue_catalog_database.fastly_logs.name
  role          = aws_iam_role.glue.name
  schedule      = "cron(30 */4 * * ? *)"

  s3_target {
    path = "s3://${aws_s3_bucket.fastly_logs.bucket}/govuk_assets"
  }

  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
    update_behavior = "LOG"
  }

  configuration = <<EOF
{
  "Version": 1.0,
  "CrawlerOutput": {
    "Partitions": {
      "AddOrUpdateBehavior": "InheritFromTable"
    }
  }
}
EOF
}

resource "aws_glue_catalog_table" "govuk_assets" {
  name          = "govuk_assets"
  description   = "Allows access to JSON data exported from Fastly"
  database_name = aws_glue_catalog_database.fastly_logs.name
  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    compressed    = true
    location      = "s3://${aws_s3_bucket.fastly_logs.bucket}/govuk_assets/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name = "ser_de_name"

      parameters = {
        paths                   = "client_ip,request_received,request_received_offset,method,url,status,protocol,request_time,time_to_generate_response,bytes,content_type,user_agent,fastly_backend,data_centre,cache_hit,cache_response,tls_client_protocol,tls_client_cipher,client_ja3"
        "ignore.malformed.json" = "true"
      }

      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    // These columns correlate with the log format set up in Fastly as below
    //
    // {
    // "client_ip":"%{json.escape(client.ip)}V",
    // "request_received":"%{begin:%Y-%m-%d %H:%M:%S.}t%{time.start.msec_frac}V",
    // "request_received_offset":"%{begin:%z}t",
    // "method":"%{json.escape(req.method)}V",
    // "url":"%{json.escape(req.url)}V",
    // "status":%>s,
    // "protocol":"%{json.escape(req.proto)}V",
    // "request_time":%{time.elapsed.sec}V.%{time.elapsed.msec_frac}V,
    // "time_to_generate_response":%{time.to_first_byte}V,
    // "bytes":%B,
    // "content_type":"%{json.escape(resp.http.Content-Type)}V",
    // "user_agent":"%{json.escape(req.http.User-Agent)}V",
    // "fastly_backend":"%{json.escape(resp.http.Fastly-Backend-Name)}V",
    // "data_centre":"%{json.escape(server.datacenter)}V",
    // "cache_hit":%{if(fastly_info.state ~"^(HIT|MISS)(?:-|$)", "true", "false")}V,
    // "cache_response":"%{regsub(fastly_info.state, "^(HIT-(SYNTH)|(HITPASS|HIT|MISS|PASS|ERROR|PIPE)).*", "\\2\\3") }V",
    // "tls_client_protocol":"%{json.escape(tls.client.protocol)}V",
    // "tls_client_cipher":"%{json.escape(tls.client.cipher)}V",
    // "client_ja3":"%{json.escape(req.http.Client-JA3)}V"
    // }
    columns {
      name    = "client_ip"
      type    = "string"
      comment = "IP address of the client that made the request"
    }
    columns {
      name    = "request_received"
      type    = "timestamp"
      comment = "Time we received the request"
    }
    columns {
      // This field is separate from the timestamp above as the Presto version
      // on AWS Athena doesn't support timestamps - expectation is that this is
      // always +0000 though
      name = "request_received_offset"

      type    = "string"
      comment = "Time offset of the request, expected to be +0000 always"
    }
    columns {
      name    = "method"
      type    = "string"
      comment = "HTTP method for this request"
    }
    columns {
      name    = "url"
      type    = "string"
      comment = "URL requested with query string"
    }
    columns {
      name    = "status"
      type    = "int"
      comment = "HTTP status code returned"
    }
    columns {
      name    = "request_time"
      type    = "double"
      comment = "Time until user received full response in seconds"
    }
    columns {
      name    = "time_to_generate_response"
      type    = "double"
      comment = "Time spent generating a response for varnish, in seconds"
    }
    columns {
      name    = "bytes"
      type    = "bigint"
      comment = "Number of bytes returned"
    }
    columns {
      name    = "content_type"
      type    = "string"
      comment = "HTTP Content-Type header returned"
    }
    columns {
      name    = "user_agent"
      type    = "string"
      comment = "User agent that made the request"
    }
    columns {
      name    = "fastly_backend"
      type    = "string"
      comment = "Name of the backend that served this request"
    }
    columns {
      name    = "data_centre"
      type    = "string"
      comment = "Name of the data centre that served this request"
    }
    columns {
      name    = "cache_hit"
      type    = "boolean"
      comment = "Whether this object is cacheable or not"
    }
    columns {
      name    = "cache_response"
      type    = "string"
      comment = "Whether the response was a HIT, MISS, PASS, ERROR, PIPE, HITPASS, or SYNTH(etic)"
    }
    columns {
      name = "tls_client_protocol"
      type = "string"
    }
    columns {
      name = "tls_client_cipher"
      type = "string"
    }
    columns {
      name = "client_ja3"
      type = "string"
    }
    columns {
      name    = "protocol"
      type    = "string"
      comment = "HTTP version used"
    }
  }

  // these correspond to directory ordering of:
  // /year=YYYY/month=MM/date=DD/file.log.gz
  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "date"
    type = "int"
  }

  parameters = {
    classification  = "json"
    compressionType = "gzip"
    typeOfDate      = "file"
  }
}

resource "aws_glue_crawler" "bouncer" {
  name          = "Bouncer fastly logs"
  description   = "Crawls the bouncer logs from fastly for allowing Athena querying"
  database_name = aws_glue_catalog_database.fastly_logs.name
  role          = aws_iam_role.glue.name
  schedule      = "cron(30 */4 * * ? *)"

  s3_target {
    path = "s3://${aws_s3_bucket.fastly_logs.bucket}/bouncer"
  }

  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
    update_behavior = "LOG"
  }

  configuration = <<EOF
{
  "Version": 1.0,
  "CrawlerOutput": {
    "Partitions": {
      "AddOrUpdateBehavior": "InheritFromTable"
    }
  }
}
EOF
}

resource "aws_glue_catalog_table" "bouncer" {
  name          = "bouncer"
  description   = "Allows access to JSON data exported from Fastly"
  database_name = aws_glue_catalog_database.fastly_logs.name
  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    compressed    = true
    location      = "s3://${aws_s3_bucket.fastly_logs.bucket}/bouncer/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name = "ser_de_name"

      parameters = {
        paths                   = "client_ip,request_received,request_received_offset,method,url,status,request_time,time_to_generate_response,content_type,user_agent,data_centre,cache_hit,cache_response"
        "ignore.malformed.json" = "true"
      }

      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    // These columns correlate with the log format set up in Fastly as below
    //
    // {
    // "client_ip":"%{json.escape(client.ip)}V",
    // "request_received":"%{begin:%Y-%m-%d %H:%M:%S.}t%{time.start.msec_frac}V",
    // "request_received_offset":"%{begin:%z}t",
    // "method":"%{json.escape(req.method)}V",
    // "host":"%{json.escape(req.http.host)}V",
    // "url":"%{json.escape(req.url)}V",
    // "status":%>s,
    // "request_time":%{time.elapsed.sec}V.%{time.elapsed.msec_frac}V,
    // "time_to_generate_response":%{time.to_first_byte}V,
    // "location":"%{json.escape(resp.http.Location)}V",
    // "user_agent":"%{json.escape(req.http.User-Agent)}V",
    // "data_centre":"%{json.escape(server.datacenter)}V",
    // "cache_hit":%{if(fastly_info.state ~"^(HIT|MISS)(?:-|$)", "true", "false")}V,
    // "cache_response":"%{regsub(fastly_info.state, "^(HIT-(SYNTH)|(HITPASS|HIT|MISS|PASS|ERROR|PIPE)).*", "\\2\\3") }V"
    // }
    columns {
      name    = "client_ip"
      type    = "string"
      comment = "IP address of the client that made the request"
    }
    columns {
      name    = "request_received"
      type    = "timestamp"
      comment = "Time we received the request"
    }
    columns {
      // This field is separate from the timestamp above as the Presto version
      // on AWS Athena doesn't support timestamps - expectation is that this is
      // always +0000 though
      name = "request_received_offset"

      type    = "string"
      comment = "Time offset of the request, expected to be +0000 always"
    }
    columns {
      name    = "method"
      type    = "string"
      comment = "HTTP method for this request"
    }
    columns {
      name    = "host"
      type    = "string"
      comment = "Host that was requested"
    }
    columns {
      name    = "url"
      type    = "string"
      comment = "URL requested with query string"
    }
    columns {
      name    = "status"
      type    = "int"
      comment = "HTTP status code returned"
    }
    columns {
      name    = "request_time"
      type    = "double"
      comment = "Time until user received full response in seconds"
    }
    columns {
      name    = "time_to_generate_response"
      type    = "double"
      comment = "Time spent generating a response for varnish, in seconds"
    }
    columns {
      name    = "location"
      type    = "string"
      comment = "HTTP Location header returned"
    }
    columns {
      name    = "user_agent"
      type    = "string"
      comment = "User agent that made the request"
    }
    columns {
      name    = "data_centre"
      type    = "string"
      comment = "Name of the data centre that served this request"
    }
    columns {
      name    = "cache_hit"
      type    = "boolean"
      comment = "Whether this object is cacheable or not"
    }
    columns {
      name    = "cache_response"
      type    = "string"
      comment = "Whether the response was a HIT, MISS, PASS, ERROR, PIPE, HITPASS, or SYNTH(etic)"
    }
  }

  // these correspond to directory ordering of:
  // /year=YYYY/month=MM/date=DD/file.log.gz
  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "date"
    type = "int"
  }

  parameters = {
    classification  = "json"
    compressionType = "gzip"
    typeOfDate      = "file"
  }
}

# Configuration for monitoring the fastly logs Athena databases continue to be
# queryable. This requires a dedicated user that can query athena and save
# the queries results

resource "aws_s3_bucket" "fastly_logs_monitoring" {
  bucket = "govuk-${var.environment}-fastly-logs-monitoring"
}

resource "aws_s3_bucket_logging" "fastly_logs_monitoring" {
  bucket = aws_s3_bucket.fastly_logs_monitoring.id

  target_bucket = "govuk-${var.environment}-aws-logging"
  target_prefix = "s3/govuk-${var.environment}-fastly-logs-monitoring/"
}

resource "aws_s3_bucket_lifecycle_configuration" "fastly_logs_monitoring" {
  bucket = aws_s3_bucket.fastly_logs_monitoring.id

  rule {
    id = "expire"

    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

# Configuration for transition lambda function that loads data from fastly logs
# Athena databases and saves it back into S3

resource "aws_s3_bucket" "transition_fastly_logs" {
  bucket = "govuk-${var.environment}-transition-fastly-logs"
}

resource "aws_s3_bucket_logging" "transition_fastly_logs" {
  bucket = aws_s3_bucket.transition_fastly_logs.id

  target_bucket = "govuk-${var.environment}-aws-logging"
  target_prefix = "s3/govuk-${var.environment}-transition-fastly-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "transition_fastly_logs" {
  bucket = aws_s3_bucket.transition_fastly_logs.id

  rule {
    id = "expire"

    status = "Enabled"

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days           = 1
      newer_noncurrent_versions = ""
    }
  }
}

# We require a user for transition to read from S3 buckets
resource "aws_iam_user" "transition_downloader" {
  name = "govuk-${var.environment}-transition-downloader"
}

data "aws_iam_policy_document" "transition_downloader_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "${aws_s3_bucket.transition_fastly_logs.arn}*",
    ]
  }
}

resource "aws_iam_policy" "transition_downloader" {
  name        = "fastly-logs-${var.environment}-transition-downloader-policy"
  policy      = data.aws_iam_policy_document.transition_downloader_policy.json
  description = "Allows downloading from the transition fastly logs bucket"
}

resource "aws_iam_policy_attachment" "transition_downloader" {
  name       = "transition-downloader-policy-attachment"
  users      = [aws_iam_user.transition_downloader.name]
  policy_arn = aws_iam_policy.transition_downloader.arn
}

resource "aws_athena_named_query" "transition_logs" {
  name     = "transition-logs-query"
  database = aws_glue_catalog_database.fastly_logs.name
  query    = <<EOF
SELECT
  (current_date - interval '1' day) date,
  count(*) count,
  status,
  host,
  url
FROM bouncer
WHERE year = year(current_date - interval '1' day)
  AND month = month(current_date - interval '1' day)
  AND date = day(current_date - interval '1' day)
GROUP BY status, host, url
HAVING count(*) >= 10
ORDER BY 2 DESC
EOF
}

data "archive_file" "transition_executor" {
  type        = "zip"
  source_file = "${path.module}/transition_logs.py"
  output_path = "${path.module}/TransitionLogs.zip"
}

resource "aws_lambda_function" "transition_executor" {
  filename         = data.archive_file.transition_executor.output_path
  source_code_hash = data.archive_file.transition_executor.output_base64sha256

  function_name = "govuk-${var.environment}-transition"
  role          = aws_iam_role.transition_executor.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.8"

  environment {
    variables = {
      NAMED_QUERY_ID = aws_athena_named_query.transition_logs.id
      DATABASE_NAME  = "${aws_athena_named_query.transition_logs.database}"
      BUCKET_NAME    = "${aws_s3_bucket.transition_fastly_logs.bucket}"
    }
  }
}

resource "aws_iam_role" "transition_executor" {
  name = "AWSLambdaRole-transition-executor"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "transition_executor_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
    effect    = "Allow"
  }

  statement {
    effect = "Allow"
    actions = [
      "athena:*",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetPartition",
      "glue:GetPartitions",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "${aws_s3_bucket.fastly_logs.arn}*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.transition_fastly_logs.arn}*",
    ]
  }
}

resource "aws_iam_policy" "transition_executor" {
  name        = "fastly-logs-${var.environment}-transition-executor-policy"
  policy      = data.aws_iam_policy_document.transition_executor_policy.json
  description = "Allows execution of various transition tasks, including S3, Glue, and Athena operations"
}

resource "aws_iam_role_policy_attachment" "transition_executor" {
  role       = aws_iam_role.transition_executor.name
  policy_arn = aws_iam_policy.transition_executor.arn
}

resource "aws_cloudwatch_event_rule" "transition_executor_daily" {
  name                = "transition_executor_daily"
  schedule_expression = "cron(30 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "transition_executor_daily" {
  rule = aws_cloudwatch_event_rule.transition_executor_daily.name
  arn  = aws_lambda_function.transition_executor.arn
}

resource "aws_lambda_permission" "cloudwatch_transition_executor_daily_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transition_executor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.transition_executor_daily.arn
}
