resource "random_bytes" "tunnel_secret" {
  length = 32
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id    = var.cf_account_id
  name          = var.tunnel_name
  config_src    = "cloudflare"
  tunnel_secret = random_bytes.tunnel_secret.base64
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "tunnel" {
  account_id = var.cf_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

# Relative path: the version of the ingress module always matches the one of this module.
module "ingress" {
  source = "../../cloudflare/cloudflare_tunnel_ingress"

  cf_domain     = var.cf_domain
  cf_account_id = var.cf_account_id
  cf_zone_id    = var.cf_zone_id
  cf_tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  services      = var.services
}

data "docker_registry_image" "cloudflared" {
  name = var.image_name
}

resource "docker_image" "cloudflared" {
  name         = "${data.docker_registry_image.cloudflared.name}@${data.docker_registry_image.cloudflared.sha256_digest}"
  keep_locally = true
}

resource "docker_container" "cloudflared" {
  name    = var.container_name
  image   = docker_image.cloudflared.image_id
  restart = "unless-stopped"

  log_driver = "json-file"
  log_opts = {
    "max-size" = "10m"
    "max-file" = "3"
  }

  command = ["tunnel", "run", "--token", sensitive(data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel.token)]

  networks_advanced {
    name = var.docker_network_name
  }
}
