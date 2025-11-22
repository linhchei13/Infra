variable "aws_region" {
  description = "AWS Region để triển khai tài nguyên"
  type        = string
  default     = "ap-southeast-2" 

variable "project_name" {
  description = "Tên dự án, dùng để đặt tên prefix cho các tài nguyên"
  type        = string
  default     = "hybrid-image-app"
}

# Tên S3 Bucket phải là duy nhất trên toàn cầu
variable "s3_bucket_name" {
  description = "Tên duy nhất cho S3 Bucket lưu ảnh"
  type        = string
  # Ví dụ: "my-unique-image-bucket-12345"
  # Bạn nên đặt giá trị này trong terraform.tfvars để dễ thay đổi và bảo mật
}