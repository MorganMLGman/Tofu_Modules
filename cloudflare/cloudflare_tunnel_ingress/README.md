# Cloudflare Tunnel Ingress

OpenTofu module for configuring Cloudflare Tunnel ingress rules and DNS records. Creates CNAME records and cloudflared ingress configuration for an existing tunnel.

## Usage

```hcl
module "tunnel_ingress" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//cloudflare/cloudflare_tunnel_ingress"

  cf_domain     = "example.com"
  cf_account_id = sensitive("your-account-id")
  cf_tunnel_id  = sensitive("your-tunnel-id")
  cf_zone_id    = sensitive("your-zone-id")

  services = [
    {
      subdomain = "grafana"
      service   = "http://localhost:3000"
    },
    {
      subdomain = "ha"
      service   = "https://localhost:8123"
      no_tls_verify = true
    },
  ]
}
```

## Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `cf_domain` | `string` | yes | - | Cloudflare domain name |
| `cf_account_id` | `string` | yes | - | Cloudflare account ID (sensitive) |
| `cf_zone_id` | `string` | yes | - | Cloudflare zone ID (sensitive) |
| `cf_tunnel_id` | `string` | yes | - | Cloudflare tunnel ID (sensitive) |
| `services` | `list(object)` | yes | - | Services to expose (see below) |

### Service object

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `subdomain` | `string` | yes | - | Subdomain for the service |
| `service` | `string` | yes | - | Backend service URL (e.g., `http://localhost:8080`) |
| `no_tls_verify` | `bool` | no | `false` | Skip TLS verification for the origin |

## What the module does

1. Creates CNAME DNS records pointing each subdomain to the tunnel
2. Configures cloudflared ingress rules for each service
3. Adds `http_status:404` catch-all ingress rule

## Outputs

| Name | Description |
|------|-------------|
| `services` | Map of subdomains to `{ hostname, service }` |
| `tunnel_config` | Complete tunnel cloudflared ingress configuration |
