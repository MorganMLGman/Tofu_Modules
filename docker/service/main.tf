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

module "image" {
  source = "../image"
  name   = var.image_name
}

# --- Container ---

locals {
  all_network_names = concat(
    var.networks,
    [for net in var.create_networks : net.name]
  )
}

resource "docker_container" "service_container" {
  name         = coalesce(var.container_name, "${var.service_name}_app")
  image        = module.image.image_id
  restart      = var.restart_policy
  network_mode = var.network_mode
  runtime      = var.runtime
  memory       = var.memory
  log_driver   = var.log_driver
  log_opts     = var.log_opts

  dynamic "volumes" {
    for_each = var.volumes
    content {
      host_path      = volumes.value.host_path
      volume_name    = volumes.value.volume_name
      container_path = volumes.value.container_path
      read_only      = volumes.value.read_only
    }
  }

  dynamic "capabilities" {
    for_each = length(var.capabilities_add) > 0 ? [var.capabilities_add] : []
    content {
      add = capabilities.value
    }
  }

  dynamic "healthcheck" {
    for_each = var.healthcheck != null ? [var.healthcheck] : []
    content {
      test         = healthcheck.value.test
      interval     = healthcheck.value.interval
      timeout      = healthcheck.value.timeout
      retries      = healthcheck.value.retries
      start_period = healthcheck.value.start_period
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

  depends_on = [docker_network.service_network]
}
