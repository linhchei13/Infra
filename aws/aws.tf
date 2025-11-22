terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# --- 1. S3 BUCKET (Lưu trữ ảnh) ---
resource "aws_s3_bucket" "image_bucket" {
  bucket = var.s3_bucket_name
  # Xóa bucket ngay cả khi còn dữ liệu (CẨN THẬN khi dùng cho production)
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-s3-bucket"
    Environment = "Dev"
  }
}

# Chặn quyền truy cập công cộng
resource "aws_s3_bucket_public_access_block" "image_bucket_access" {
  bucket = aws_s3_bucket.image_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# --- 2. SQS QUEUE (Hàng đợi thông báo) ---
resource "aws_sqs_queue" "image_queue" {
  name                      = "${var.project_name}-queue"
  visibility_timeout_seconds = 60  # Thời gian chờ cho worker xử lý
  message_retention_seconds  = 86400 # Lưu message trong 1 ngày

  tags = {
    Name        = "${var.project_name}-sqs-queue"
    Environment = "Dev"
  }
}

# --- 3. DYNAMODB TABLE (Lưu kết quả) ---
resource "aws_dynamodb_table" "result_table" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "request_id"

  attribute {
    name = "request_id"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-dynamodb-table"
    Environment = "Dev"
  }
}

# Tạo Policy cấp quyền tối thiểu
resource "aws_iam_policy" "api_server_policy" {
  name        = "${var.project_name}-api-policy"
  description = "Policy for OpenStack API Server to access S3, SQS, and DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Upload"
        Effect = "Allow"
        Action = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.image_bucket.arn}/*"
      },
      {
        Sid    = "SQSSend"
        Effect = "Allow"
        Action = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.image_queue.arn
      },
      {
        Sid    = "DynamoDBRead"
        Effect = "Allow"
        Action = ["dynamodb:GetItem"]
        Resource = aws_dynamodb_table.result_table.arn
      }
    ]
  })
}