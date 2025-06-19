resource "aws_s3_bucket" "fastly_logs" {
  bucket = "govuk-${var.govuk_environment}-fastly-logs"
}

resource "aws_s3_bucket_logging" "fastly_logs" {
  bucket = aws_s3_bucket.fastly_logs.id

  target_bucket = data.tfe_outputs.logging.nonsensitive_values.aws_logging_bucket_id
  target_prefix = "s3/govuk-${var.govuk_environment}-fastly-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "fastly_logs" {
  bucket = aws_s3_bucket.fastly_logs.id

  rule {
    id = "Expire-after-120-days"

    status = "Enabled"

    expiration {
      days = 120
    }
  }
}

resource "aws_glue_catalog_database" "fastly_logs" {
  name        = "fastly_logs"
  description = "Used to browse the CDN log files that Fastly sends"
}

resource "aws_iam_role_policy_attachment" "aws-glue-service-role-service-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  role       = aws_iam_role.glue.name
}

data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue" {
  name = "AWSGlueServiceRole-fastly-logs"

  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
}

data "aws_iam_policy_document" "fastly_logs_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.fastly_logs.arn,
      "${aws_s3_bucket.fastly_logs.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "fastly_logs_policy" {
  name = "govuk-${var.govuk_environment}-fastly-logs-glue-policy"
  role = aws_iam_role.glue.id

  policy = data.aws_iam_policy_document.fastly_logs_role_policy.json
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
  bucket = "govuk-${var.govuk_environment}-fastly-logs-monitoring"
}

resource "aws_s3_bucket_logging" "fastly_logs_monitoring" {
  bucket = aws_s3_bucket.fastly_logs_monitoring.id

  target_bucket = data.tfe_outputs.logging.nonsensitive_values.aws_logging_bucket_id
  target_prefix = "s3/govuk-${var.govuk_environment}-fastly-logs-monitoring/"
}

resource "aws_s3_bucket_lifecycle_configuration" "fastly_logs_monitoring" {
  bucket = aws_s3_bucket.fastly_logs_monitoring.id

  rule {
    id = "Expire-after-7-days"

    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

resource "aws_iam_user" "athena_monitoring" {
  name = "govuk-${var.govuk_environment}-fastly-logs-athena-monitoring"
}

data "aws_iam_policy_document" "athena_monitoring_policy" {
  statement {
    effect    = "Allow"
    actions   = ["athena:*"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetPartition",
      "glue:GetPartitions"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.fastly_logs.arn,
      "${aws_s3_bucket.fastly_logs.arn}/*"
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
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.fastly_logs_monitoring.arn,
      "${aws_s3_bucket.fastly_logs_monitoring.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "athena_monitoring" {
  name   = "fastly-logs-${var.govuk_environment}-fastly-logs-athena-monitoring-policy"
  policy = data.aws_iam_policy_document.athena_monitoring_policy.json
}

resource "aws_iam_user_policy_attachment" "athena_monitoring" {
  user       = aws_iam_user.athena_monitoring.name
  policy_arn = aws_iam_policy.athena_monitoring.arn
}

# Configuration for transition lambda function that loads data from fastly logs
# Athena databases and saves it back into S3

resource "aws_s3_bucket" "transition_fastly_logs" {
  bucket = "govuk-${var.govuk_environment}-transition-fastly-logs"
}

resource "aws_s3_bucket_logging" "transition_fastly_logs" {
  bucket = aws_s3_bucket.transition_fastly_logs.id

  target_bucket = data.tfe_outputs.logging.nonsensitive_values.aws_logging_bucket_id
  target_prefix = "s3/govuk-${var.govuk_environment}-transition-fastly-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "transition_fastly_logs" {
  bucket = aws_s3_bucket.transition_fastly_logs.id

  rule {
    id = "Expire-after-30-days"

    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# We require a user for transition to read from S3 buckets
resource "aws_iam_user" "transition_downloader" {
  name = "govuk-${var.govuk_environment}-transition-downloader"
}

data "aws_iam_policy_document" "transition_downloader_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListObject"
    ]
    resources = [
      aws_s3_bucket.transition_fastly_logs.arn,
      "${aws_s3_bucket.transition_fastly_logs.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "transition_downloader" {
  name   = "fastly-logs-${var.govuk_environment}-transition-downloader-policy"
  policy = data.aws_iam_policy_document.transition_downloader_policy.json
}

resource "aws_iam_user_policy_attachment" "transition_downloader" {
  user       = aws_iam_user.transition_downloader.name
  policy_arn = aws_iam_policy.transition_downloader.arn
}

resource "aws_athena_named_query" "transition_logs" {
  name     = "transition-logs-query"
  database = aws_glue_catalog_database.fastly_logs.name
  query    = file("${path.module}/transition_logs_query.sql")
}

data "archive_file" "transition_executor" {
  type        = "zip"
  source_file = "${path.module}/lambda-source/main.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "transition_executor" {
  filename         = data.archive_file.transition_executor.output_path
  source_code_hash = data.archive_file.transition_executor.output_base64sha256

  function_name = "govuk-${var.govuk_environment}-transition"
  role          = aws_iam_role.transition_executor.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.13"

  environment {
    variables = {
      NAMED_QUERY_ID = "${aws_athena_named_query.transition_logs.id}"
      DATABASE_NAME  = "${aws_athena_named_query.transition_logs.database}"
      BUCKET_NAME    = "${aws_s3_bucket.transition_fastly_logs.bucket}"
    }
  }
}

data "aws_iam_policy_document" "transition_executor_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "transition_executor" {
  name = "AWSLambdaRole-transition-executor"

  assume_role_policy = data.aws_iam_policy_document.transition_executor_assume_role.json
}

data "aws_iam_policy_document" "transition_executor_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["athena:*"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetPartition",
      "glue:GetPartitions"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.fastly_logs.arn,
      "${aws_s3_bucket.fastly_logs.arn}/*"
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
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.transition_fastly_logs.arn,
      "${aws_s3_bucket.transition_fastly_logs.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "transition_executor" {
  name   = "fastly-logs-${var.govuk_environment}-transition-executor-policy"
  policy = data.aws_iam_policy_document.transition_executor_policy.json
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
