output "aws_region" {
  value       = var.aws_region
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.image_bucket.id
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.result_table.name
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.s3_distribution.id
}
