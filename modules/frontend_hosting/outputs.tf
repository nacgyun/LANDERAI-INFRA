output "bucket_name" {
  description = "S3 bucket that stores the built frontend."
  value       = aws_s3_bucket.frontend.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket that stores the built frontend."
  value       = aws_s3_bucket.frontend.arn
}

output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.frontend.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.frontend.arn
}

output "distribution_hosted_zone_id" {
  description = "Canonical hosted zone ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.frontend.hosted_zone_id
}

output "distribution_domain_name" {
  description = "CloudFront domain serving the frontend."
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "url" {
  description = "HTTPS URL of the frontend."
  value       = length(var.aliases) > 0 ? "https://${var.aliases[0]}" : "https://${aws_cloudfront_distribution.frontend.domain_name}"
}
