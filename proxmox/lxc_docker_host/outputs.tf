output "ct_id" {
  description = "The unique identifier of the container"
  value       = module.lxc_base.ct_id
}

output "ct_hostname" {
  description = "The hostname of the container"
  value       = module.lxc_base.ct_hostname
}

output "ct_ipv4_address" {
  description = "IPv4 address of the container (first network interface)"
  value       = module.lxc_base.ct_ipv4_address
}

output "ct_status" {
  description = "Current status of the container"
  value       = module.lxc_base.ct_status
}

output "ct_node_name" {
  description = "Name of the node where container is running"
  value       = module.lxc_base.ct_node_name
}

output "ct_mac_addresses" {
  description = "Effective MAC addresses keyed by interface name (generated or caller-supplied)"
  value       = module.lxc_base.ct_mac_addresses
}

output "docker_install_result" {
  description = "Result (stdout) of the Docker installation script"
  value       = ssh_resource.docker_install.result
}

# --- Docker provider connection outputs ---

output "docker_host_ssh" {
  description = "Docker provider host string for SSH connection (use in provider 'docker' { host = ... })"
  value       = "ssh://${var.ssh_user}@${module.lxc_base.ct_ipv4_address}:${var.ssh_port}"
}

output "docker_host_tcp" {
  description = "Docker provider host string for TCP connection (null when docker_enable_tcp is false)"
  value       = var.docker_enable_tcp ? "tcp://${module.lxc_base.ct_ipv4_address}:${var.docker_tcp_port}" : null
}

output "docker_ssh_opts" {
  description = "Recommended ssh_opts for the Docker provider"
  value       = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
}
