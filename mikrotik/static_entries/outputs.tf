output "dhcp_lease_addresses" {
  description = "Addresses of created DHCP leases."
  value       = { for k, v in routeros_ip_dhcp_server_lease.static_lease : k => v.address }
  sensitive   = true
}

output "dhcp_lease_mac_addresses" {
  description = "MAC addresses of created DHCP leases."
  value       = { for k, v in routeros_ip_dhcp_server_lease.static_lease : k => v.mac_address }
  sensitive   = true
}

output "dns_static_names" {
  description = "Names of created DNS static entries."
  value       = { for k, v in routeros_ip_dns_record.static_dns : k => v.name }
}
