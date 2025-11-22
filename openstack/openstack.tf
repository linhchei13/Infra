terraform {
  required_version = ">= 1.0.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

provider "openstack" {
  user_name   = var.os_username
  password    = var.os_password
  tenant_name = var.os_project_name
  auth_url    = var.os_auth_url
  region      = var.os_region_name
}

data "openstack_networking_network_v2" "ext_net_info" {
  # CŨ: network_id = var.external_network_id
  # MỚI: Tìm theo tên, dùng biến mới
  name = var.external_network_name
}
# --- 1. NETWORKING (Mạng nội bộ cho VM) ---
resource "openstack_networking_network_v2" "app_network" {
  name           = "app-private-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "app_subnet" {
  name            = "app-private-subnet-simple"
  network_id      = openstack_networking_network_v2.app_network.id
  cidr            = "192.168.20.0/24" # Đổi dải IP khác một chút để tránh trùng lặp nếu bạn chạy lab nhiều lần
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "1.1.1.1"] # Quan trọng để phân giải tên miền AWS
}

# Router để đi ra Internet
resource "openstack_networking_router_v2" "app_router" {
  name                = "app-router-simple"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.ext_net_info.id
}
resource "openstack_networking_router_interface_v2" "app_router_interface" {
  router_id = openstack_networking_router_v2.app_router.id

  subnet_id = openstack_networking_subnet_v2.app_subnet.id
}

# --- 2. SECURITY GROUP ---
resource "openstack_compute_secgroup_v2" "app_sg" {
  name        = "app-security-group-simple"
  description = "Security group cho single API backend"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0" # Cho phép SSH để debug
  }

  rule {
    from_port   = 8000
    to_port     = 8000
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0" # Mở trực tiếp port API ra internet để test
  }
}

# --- 3. COMPUTE INSTANCE (1 VM duy nhất) ---
# Render User Data template
data "template_file" "user_data_script" {
  template = file("${path.module}/templates/user_data.sh.tpl")
  vars = {
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    aws_default_region    = var.aws_default_region
    s3_bucket_name        = var.s3_bucket_name
    sqs_queue_url         = var.sqs_queue_url
    dynamo_table_name     = var.dynamo_table_name
  }
}

# Tạo port mạng trước để dễ gán Floating IP sau này
resource "openstack_networking_port_v2" "app_port" {
  name           = "app-port-simple"
  network_id     = openstack_networking_network_v2.app_network.id
  admin_state_up = "true"
  security_group_ids = [openstack_compute_secgroup_v2.app_sg.id]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.app_subnet.id
  }
}

resource "openstack_compute_instance_v2" "app_server" {
  name            = "backend-api-single"
  image_name      = var.image_name
  flavor_name     = var.flavor_name
  key_pair        = var.key_pair_name
  
  user_data       = data.template_file.user_data_script.rendered

  # Gán port đã tạo ở trên vào VM
  network {
    port = openstack_networking_port_v2.app_port.id
  }
  
  # Đảm bảo có mạng ra ngoài trước khi tạo VM
  depends_on = [openstack_networking_router_interface_v2.app_router_interface]
}

# --- 4. FLOATING IP (Gán trực tiếp cho VM) ---
resource "openstack_networking_floatingip_v2" "vm_fip" {
  pool = data.openstack_networking_network_v2.ext_net_info.name
}

resource "openstack_networking_floatingip_associate_v2" "vm_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.vm_fip.address
  port_id     = openstack_networking_port_v2.app_port.id # Gán vào port của VM
}