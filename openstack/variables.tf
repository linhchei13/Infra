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

# --- OpenStack Auth ---
variable "os_auth_url" { description = "OpenStack Auth URL" }
variable "os_project_name" { description = "OpenStack Tenant/Project Name" }
variable "os_username" { description = "OpenStack Username" }
variable "os_password" { description = "OpenStack Password" }
variable "os_region_name" { description = "OpenStack Region" }
variable "os_domain_name" {description = "OpenStack domain"}

# --- VM Configuration ---
variable "image_name" {
  description = "Tên image Ubuntu trên OpenStack (VD: Ubuntu 22.04)"
  type        = string
  default     = "Ubuntu 22.04"
}

variable "flavor_name" {
  description = "Tên flavor (cấu hình CPU/RAM) cho VM"
  type        = string
  default     = "m1.small"
}

variable "key_pair_name" {
  description = "Tên SSH key pair đã có trên OpenStack"
  type        = string
}

variable "external_network_id" {
  description = "UUID hoặc tên của mạng Public (External) trên OpenStack để cấp Floating IP"
  type        = string
}
variable "external_network_name" {
  description = "TÊN của mạng Public (External) trên OpenStack (ví dụ: public, ext-net)"
  type        = string
}

# --- AWS Config (Truyền vào ứng dụng Python) ---
variable "aws_access_key_id" { description = "AWS Access Key" }
variable "aws_secret_access_key" { description = "AWS Secret Key" }
variable "aws_default_region" { description = "AWS Region (e.g., us-east-1)" }
variable "s3_bucket_name" { description = "AWS S3 Bucket Name" }

variable "swift_container_name" {
  description = "Name of the OpenStack Swift container"
  type        = string
  default     = "my-swift-container"
}