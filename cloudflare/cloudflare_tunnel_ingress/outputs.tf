output "services" {
  description = "Map of services with their full hostname and service URL"
  value = {
    for service in var.services :
    service.subdomain => {
      hostname = "${service.subdomain}.${var.cf_domain}"
      service  = service.service
    }
  }
}

output "tunnel_config" {
  description = "Tunnel cloudflared configuration"
  value       = cloudflare_zero_trust_tunnel_cloudflared_config.config.config
}
