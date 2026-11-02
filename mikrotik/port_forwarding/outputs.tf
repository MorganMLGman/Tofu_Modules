output "nat_rule_id" {
  description = "ID of the created NAT rule"
  value       = routeros_ip_firewall_nat.port_forward.id
  sensitive   = true
}

output "filter_rule_id" {
  description = "ID of the created firewall filter rule"
  value       = routeros_ip_firewall_filter.allow_port_forward.id
  sensitive   = true
}

output "forwarded_address" {
  description = "The internal IP address traffic is forwarded to"
  value       = var.internal_ip
  sensitive   = true
}

output "forwarded_port" {
  description = "The internal port traffic is forwarded to"
  value       = var.internal_port != null ? var.internal_port : var.external_port
}
