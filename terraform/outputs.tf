output "vm_ips" {
  value = [for server in hcloud_server.microsoft-presidio : server.ipv4_address]
}

output "floating_ip" {
  description = "Floating IP address assigned to the VM"
  value       = hcloud_floating_ip.ip[0].ip_address
}
