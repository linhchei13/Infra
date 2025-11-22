variable "aws_region" {
  description = "AWS Region để triển khai tài nguyên"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Tên dự án, dùng để đặt tên prefix cho các tài nguyên"
  type        = string
  default     = "hybrid-image-app"
}

variable "s3_bucket_name" {
  description = "Tên duy nhất cho S3 Bucket lưu ảnh"
  type        = string
}

variable "dynamodb_table_name" {
    description = "Tên bảng DynamoDB lưu kết quả"
    type = string
    default = "RecognitionResults"
}
variable "aws_access_key" {
  type        = string
  description = "AWS Access Key ID"
  sensitive   = true # Đánh dấu là thông tin nhạy cảm
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Access Key"
  sensitive   = true # Đánh dấu là thông tin nhạy cảm
}
