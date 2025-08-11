output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.app_config.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.app_config.arn
}