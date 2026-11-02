# docker/cloudflared

Cloudflare tunnel + DNS/ingress + a `cloudflared` container on an existing Docker network, in one call.
Replaces the tunnel / token / `cloudflared` container / `cloudflare_tunnel_ingress` block copied across the `*_docker` workspaces.

Needs the `cloudflare` and `docker` providers configured in the caller. Access policies stay separate: use `cloudflare/cloudflare_zero_trust_access_application`.

```hcl
module "cloudflared" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//docker/cloudflared?ref=<tag>"

  tunnel_name         = "tofu_tracefinity"
  docker_network_name = docker_network.tracefinity.name

  cf_domain     = local.cf_domain
  cf_account_id = local.secrets.cloudflare.cloudflare_account_id
  cf_zone_id    = local.secrets.cloudflare.cloudflare_morganmlg_zone_id

  services = [{ subdomain = "tracefinity", service = "http://tracefinity:3000" }]
}
```

Add `depends_on = [docker_container.app]` on the call if the network must be in use first.
Options: `network_mode = "host"` (instead of `docker_network_name`, to reach services as `localhost`), `tunnel_secret` (adopt a tunnel whose secret lives in another resource, e.g. a `random_id`; leaving it null generates one), `container_name`, `image_name`.
Outputs: `tunnel_id`, `container_name`.
