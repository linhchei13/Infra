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
variable "sqs_queue_url" { description = "AWS SQS Queue URL" }
variable "dynamo_table_name" { description = "AWS DynamoDB Table Name" }