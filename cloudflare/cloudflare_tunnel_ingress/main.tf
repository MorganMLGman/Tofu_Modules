
resource "cloudflare_dns_record" "dns_record" {
  for_each = { for service in var.services : service.subdomain => service }

  zone_id = var.cf_zone_id
  comment = "Managed by OpenTofu"
  content = sensitive("${var.cf_tunnel_id}.cfargotunnel.com")
  name    = each.value.subdomain
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "config" {
  account_id = var.cf_account_id
  tunnel_id  = var.cf_tunnel_id
  config = {
    ingress = concat(
      [
        for service in var.services : {
          hostname       = "${service.subdomain}.${var.cf_domain}"
          service        = service.service
          origin_request = service.no_tls_verify ? { no_tls_verify = true } : null
        }
      ],
      [
        {
          service = "http_status:404"
        }
      ]
    )
  }
}
