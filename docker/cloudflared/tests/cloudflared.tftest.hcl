mock_provider "cloudflare" {}
mock_provider "random" {}
mock_provider "docker" {
  mock_data "docker_registry_image" {
    defaults = {
      sha256_digest = "sha256:abc123"
    }
  }
}

variables {
  tunnel_name         = "tofu_test"
  docker_network_name = "app"
  cf_domain           = "example.com"
  cf_account_id       = "acc"
  cf_zone_id          = "zone"
  services            = [{ subdomain = "app", service = "http://app:3000" }]
}

run "container_joins_the_given_network_with_pinned_image" {
  command = plan

  assert {
    condition     = docker_image.cloudflared.name == "cloudflare/cloudflared:latest@sha256:abc123"
    error_message = "cloudflared image must be pinned by digest."
  }

  assert {
    condition     = one(docker_container.cloudflared.networks_advanced).name == "app"
    error_message = "cloudflared must join docker_network_name."
  }

  assert {
    condition     = output.container_name == "cloudflared"
    error_message = "Default container name changed."
  }
}

run "ingress_module_receives_the_services" {
  command = plan

  assert {
    condition     = length(module.ingress.services) == 1 && module.ingress.services["app"].hostname == "app.example.com"
    error_message = "Services must be forwarded to the ingress module."
  }
}

run "host_mode_and_adopted_secret" {
  command = plan

  variables {
    docker_network_name = null
    network_mode        = "host"
    tunnel_secret       = "c2VjcmV0"
  }

  assert {
    condition     = docker_container.cloudflared.network_mode == "host" && length(docker_container.cloudflared.networks_advanced) == 0
    error_message = "network_mode host must replace the network attachment."
  }

  assert {
    condition     = length(random_bytes.tunnel_secret) == 0
    error_message = "A supplied tunnel_secret must suppress the generated one."
  }
}

run "network_or_mode_is_required" {
  command = plan

  variables {
    docker_network_name = null
  }

  expect_failures = [var.docker_network_name]
}
