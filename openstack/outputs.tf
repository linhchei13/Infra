output "load_balancer_public_ip" {
  description = "Địa chỉ IP Public chính thức để truy cập API (qua Load Balancer)"
  value       = openstack_networking_floatingip_v2.lb_fip.address
}

output "backend_private_ips" {
    description = "Địa chỉ IP Private của các backend server (để debug/SSH từ trong mạng)"
    value = openstack_compute_instance_v2.app_server.*.access_ip_v4
}