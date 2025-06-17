output "govuk_fastly_logs_s3_bucket_arn" {
  value       = aws_s3_bucket.fastly_logs.arn
  description = "The ARN of the S3 bucket where Fastly logs are stored."
}
