output "backend_public_ip" {
  description = "Địa chỉ IP Public trực tiếp của VM Backend để test"
  value       = openstack_networking_floatingip_v2.vm_fip.address
}

output "backend_private_ip" {
    description = "Địa chỉ IP Private trong mạng nội bộ OpenStack"
    value = openstack_compute_instance_v2.app_server.access_ip_v4
}