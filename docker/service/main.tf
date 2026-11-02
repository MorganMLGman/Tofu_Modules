# --- Networks ---

resource "docker_network" "service_network" {
  for_each = { for net in var.create_networks : net.name => net }

  name   = each.value.name
  driver = each.value.driver

  dynamic "ipam_config" {
    for_each = each.value.subnet != null ? [each.value.subnet] : []
    content {
      subnet = ipam_config.value
    }
  }
}

# --- Image ---

data "docker_registry_image" "registry_image" {
  name = var.image_name
}

# Pinned by digest: with a bare tag plus pull_triggers the provider updates state but never re-pulls,
# so image_id goes stale and the container is not recreated.
resource "docker_image" "service_image" {
  name         = "${data.docker_registry_image.registry_image.name}@${data.docker_registry_image.registry_image.sha256_digest}"
  keep_locally = true
}

# --- Container ---

locals {
  all_network_names = concat(
    var.networks,
    [for net in var.create_networks : net.name]
  )
}

resource "docker_container" "service_container" {
  name    = "${var.service_name}_app"
  image   = docker_image.service_image.image_id
  restart = var.restart_policy

  dynamic "volumes" {
    for_each = var.volumes
    content {
      host_path      = volumes.value.host_path
      container_path = volumes.value.container_path
      read_only      = volumes.value.read_only
    }
  }

  dynamic "ports" {
    for_each = var.ports
    content {
      internal = ports.value.internal
      external = ports.value.external
      protocol = ports.value.protocol
    }
  }

  dynamic "networks_advanced" {
    for_each = local.all_network_names
    content {
      name = networks_advanced.value
    }
  }

  dynamic "labels" {
    for_each = var.labels
    content {
      label = labels.key
      value = labels.value
    }
  }

  dynamic "devices" {
    for_each = var.devices
    content {
      host_path      = devices.value.host_path
      container_path = devices.value.container_path != null ? devices.value.container_path : devices.value.host_path
      permissions    = devices.value.permissions
    }
  }

  env     = var.environment_variables
  command = length(var.command) > 0 ? var.command : null

  depends_on = [
    docker_image.service_image,
    docker_network.service_network
  ]
}
