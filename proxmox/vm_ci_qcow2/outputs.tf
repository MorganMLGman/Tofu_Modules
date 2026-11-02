output "vm_id" {
  description = "The unique identifier of the VM"
  value       = proxmox_virtual_environment_vm.vm.vm_id
}

output "vm_name" {
  description = "The name of the VM"
  value       = proxmox_virtual_environment_vm.vm.name
}

output "vm_ipv4_addresses" {
  description = "All IPv4 addresses assigned to the VM"
  value       = flatten(proxmox_virtual_environment_vm.vm.ipv4_addresses)
}

output "vm_ipv4_address" {
  description = "IPv4 addresses matching 192.x.x.x range (local network)"
  value       = [for ip in flatten(proxmox_virtual_environment_vm.vm.ipv4_addresses) : ip if ip != null && can(tostring(ip)) && startswith(ip, "192.")]
}

output "vm_ipv4_address_tailscale" {
  description = "IPv4 addresses matching 100.x.x.x range (Tailscale)"
  value       = [for ip in flatten(proxmox_virtual_environment_vm.vm.ipv4_addresses) : ip if ip != null && can(tostring(ip)) && startswith(ip, "100.")]
}

output "vm_ipv6_addresses" {
  description = "All IPv6 addresses assigned to the VM"
  value       = flatten(proxmox_virtual_environment_vm.vm.ipv6_addresses)
}

output "vm_mac_addresses" {
  description = "MAC addresses of the VM network interfaces"
  value       = proxmox_virtual_environment_vm.vm.mac_addresses
}

output "vm_network_interface_names" {
  description = "Network interface names published by QEMU agent"
  value       = proxmox_virtual_environment_vm.vm.network_interface_names
}

output "vm_status" {
  description = "Current status of the VM"
  value       = proxmox_virtual_environment_vm.vm.started ? "running" : "stopped"
}

output "vm_node_name" {
  description = "Name of the node where VM is running"
  value       = proxmox_virtual_environment_vm.vm.node_name
}

output "pcie_mappings" {
  description = "Created PCIe hardware mappings"
  value       = { for name, mapping in proxmox_virtual_environment_hardware_mapping_pci.pcie_mapping : name => mapping.id }
}