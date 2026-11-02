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
  value       = local.container_ipv4
}

output "ct_ipv4_map" {
  description = "Full IPv4 map of the container keyed by interface name"
  value       = proxmox_virtual_environment_container.lxc.ipv4
}

output "ct_status" {
  description = "Current status of the container"
  value       = proxmox_virtual_environment_container.lxc.started ? "running" : "stopped"
}

output "ct_node_name" {
  description = "Name of the node where container is running"
  value       = proxmox_virtual_environment_container.lxc.node_name
}

output "ct_mac_addresses" {
  description = "Effective MAC addresses keyed by interface name (generated from hostname + interface name, or caller-supplied)"
  value = {
    for idx, iface in var.ct_network_interfaces :
    iface.name => local.effective_mac_addresses[idx]
  }
}

output "provisioner_result" {
  description = "Stdout of the SSH provisioner script (null when nothing is provisioned)"
  value       = one(ssh_resource.provisioner[*].result)
}

output "docker_host_ssh" {
  description = "Value for the docker provider's host argument (null when docker is disabled)"
  value       = var.docker != null ? "ssh://${var.ssh_user}@${local.ssh_host}:${var.ssh_port}" : null
}

output "docker_host_tcp" {
  description = "Docker TCP endpoint (null unless docker.enable_tcp is true)"
  value       = try(var.docker.enable_tcp, false) ? "tcp://${local.ssh_host}:${var.docker.tcp_port}" : null
}

output "docker_ssh_opts" {
  description = "Recommended ssh_opts for the docker provider"
  value       = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
}

output "wait_complete" {
  description = "Opaque token that resolves after post-creation wait; reference this output to establish ordering"
  value       = time_sleep.wait_for_boot.id
}
