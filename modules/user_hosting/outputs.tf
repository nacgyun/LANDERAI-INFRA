output "bucket_name" {
  description = "S3 bucket containing published user sites."
  value       = aws_s3_bucket.hosting.bucket
}

output "bucket_arn" {
  description = "ARN of the published user-site bucket."
  value       = aws_s3_bucket.hosting.arn
}

output "distribution_id" {
  description = "CloudFront distribution ID for user sites."
  value       = aws_cloudfront_distribution.hosting.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN for user sites."
  value       = aws_cloudfront_distribution.hosting.arn
}

output "distribution_domain_name" {
  description = "CloudFront domain serving user sites."
  value       = aws_cloudfront_distribution.hosting.domain_name
}

output "distribution_hosted_zone_id" {
  description = "Canonical hosted zone ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.hosting.hosted_zone_id
}
