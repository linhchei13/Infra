output "aws_region" {
  value       = var.aws_region
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.image_bucket.id
}

output "sqs_queue_url" {
  value       = aws_sqs_queue.image_queue.url
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.result_table.name
}
