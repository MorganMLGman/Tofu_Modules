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
  value       = local.mac_addresses
}

output "provisioner_result" {
  description = "Stdout of the SSH provisioner script (null when nothing is provisioned)"
  value       = one(ssh_resource.provisioner[*].result)
}

output "docker_host_ssh" {
  description = "Value for the docker provider's host argument (null when docker is disabled)"
  value       = local.docker_host_ssh
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

output "connection" {
  description = "Everything a downstream workspace needs about this container, as one object. Export it as a single root output instead of one output per field."
  value = {
    id              = proxmox_virtual_environment_container.lxc.vm_id
    hostname        = var.ct_hostname
    ip              = local.container_ipv4
    mac_addresses   = local.mac_addresses
    docker_host_ssh = local.docker_host_ssh
    docker_ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
  }
}
