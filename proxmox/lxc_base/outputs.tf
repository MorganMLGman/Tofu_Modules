output "ct_id" {
  description = "The unique identifier of the container"
  value       = proxmox_virtual_environment_container.lxc.vm_id
}

output "ct_hostname" {
  description = "The hostname of the container"
  value       = var.ct_hostname
}

output "ct_ipv4_address" {
  description = "IPv4 address of the container (first non-empty across all interfaces)"
  value       = try(coalesce([for iface in var.ct_network_interfaces : lookup(proxmox_virtual_environment_container.lxc.ipv4, iface.name, "")]...), "")
}

output "ct_status" {
  description = "Current status of the container"
  value       = proxmox_virtual_environment_container.lxc.started ? "running" : "stopped"
}

output "ct_node_name" {
  description = "Name of the node where container is running"
  value       = proxmox_virtual_environment_container.lxc.node_name
}

output "lxc_ipv4_map" {
  description = "Full IPv4 map of the container keyed by interface name"
  value       = proxmox_virtual_environment_container.lxc.ipv4
}

output "ct_mac_addresses" {
  description = "Effective MAC addresses keyed by interface name (generated or caller-supplied)"
  value = {
    for idx, iface in var.ct_network_interfaces :
    iface.name => local.effective_mac_addresses[idx]
  }
}

output "wait_complete" {
  description = "Opaque token that resolves after post-creation wait; reference this output to establish ordering"
  value       = time_sleep.wait_for_boot.id
}
