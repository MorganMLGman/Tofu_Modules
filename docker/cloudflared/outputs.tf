output "tunnel_id" {
  description = "Cloudflare tunnel ID"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  sensitive   = true
}

output "container_name" {
  description = "Name of the cloudflared container"
  value       = docker_container.cloudflared.name
}
