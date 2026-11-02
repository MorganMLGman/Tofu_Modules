output "applications" {
  description = "Map of subdomains to their application details"
  value = {
    for subdomain, app in cloudflare_zero_trust_access_application.app :
    subdomain => {
      id       = app.id
      name     = app.name
      hostname = "${subdomain}.${var.cf_domain}"
    }
  }
}

output "group_ids" {
  description = "Map of access group names to their resolved IDs"
  value       = local.group_ids
}

output "service_token_client_ids" {
  description = "Map of service token names to their { id, client_id } (not sensitive)"
  value = {
    for name, token in cloudflare_zero_trust_access_service_token.token :
    name => {
      id        = token.id
      client_id = token.client_id
    }
  }
}

output "service_token_secrets" {
  description = "Map of service token names to their client_secret. Only populated at create/rotate time — bump client_secret_version to rotate."
  value = {
    for name, token in cloudflare_zero_trust_access_service_token.token :
    name => token.client_secret
  }
  sensitive = true
}
