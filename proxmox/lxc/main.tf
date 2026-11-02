locals {
  is_dhcp      = var.ct_ipv4_address == "dhcp"
  auto_gateway = local.is_dhcp ? null : cidrhost(var.ct_ipv4_address, 1)
  ipv4_gateway = var.ct_ipv4_gateway != null ? var.ct_ipv4_gateway : local.auto_gateway

  effective_ip_configs = length(var.ct_ip_configs) > 0 ? var.ct_ip_configs : [
    {
      ipv4_address = var.ct_ipv4_address
      ipv4_gateway = local.ipv4_gateway
    }
  ]

  # Derived from hostname + interface name instead of random_id, so the MAC is known at plan time:
  # a DHCP reservation can be written before the container exists, with no -target bootstrap.
  # Renaming the host or an interface changes the MAC; pin mac_address to keep it.
  effective_mac_addresses = [
    for iface in var.ct_network_interfaces :
    iface.mac_address != null ? iface.mac_address : upper(format("BC:24:11:%s:%s:%s",
      substr(md5("${var.ct_hostname}/${iface.name}"), 0, 2),
      substr(md5("${var.ct_hostname}/${iface.name}"), 2, 2),
      substr(md5("${var.ct_hostname}/${iface.name}"), 4, 2)
    ))
  ]

  # Docker hosts get roomier, keyctl-enabled defaults; an explicit value always wins.
  unprivileged     = coalesce(var.ct_unprivileged, var.nvidia == null)
  memory_dedicated = coalesce(var.ct_memory_dedicated, var.docker != null ? 1024 : 512)
  disk_size        = coalesce(var.ct_disk_size, var.docker != null ? 16 : 8)
  feature_keyctl   = coalesce(var.ct_feature_keyctl, var.docker != null)

  tags = concat(
    var.ct_tags,
    ["tofu"],
    var.docker != null ? ["docker"] : [],
    var.nvidia != null ? ["nvidia"] : [],
  )

  device_passthrough = concat(
    [for d in(var.nvidia != null ? var.nvidia.devices : []) : { path = d, deny_write = null, gid = null, mode = null, uid = null }],
    var.ct_device_passthrough
  )

  container_ipv4 = try(coalesce([for iface in var.ct_network_interfaces : lookup(proxmox_virtual_environment_container.lxc.ipv4, iface.name, "")]...), "")
  ssh_host       = var.ssh_host != null ? var.ssh_host : local.container_ipv4

  docker_host_ssh = var.docker != null ? "ssh://${var.ssh_user}@${local.ssh_host}:${var.ssh_port}" : null
  mac_addresses   = { for idx, iface in var.ct_network_interfaces : iface.name => local.effective_mac_addresses[idx] }

  docker_install_script = var.docker == null ? "" : templatefile("${path.module}/scripts/install_docker.sh", {
    docker_daemon_config = var.docker.daemon_config
    docker_compose       = var.docker.install_compose
    docker_enable_tcp    = var.docker.enable_tcp
    docker_tcp_port      = var.docker.tcp_port
  })

  nvidia_install_script = var.nvidia == null ? "" : templatefile("${path.module}/scripts/install_nvidia.sh", {
    nvidia_driver_version = var.nvidia.driver_version
  })

  # Order matters: the NVIDIA toolkit step reconfigures the Docker daemon.
  provisioner_script = join("\n", compact([
    local.docker_install_script,
    local.nvidia_install_script,
    var.ct_provisioner_script_content,
  ]))
}

resource "proxmox_virtual_environment_container" "lxc" {
  node_name   = var.node_name
  vm_id       = var.ct_id
  description = var.ct_description

  unprivileged  = local.unprivileged
  protection    = var.ct_protection
  started       = var.ct_started
  start_on_boot = var.ct_start_on_boot

  operating_system {
    template_file_id = var.ct_operating_system_template_file_id
    type             = var.ct_operating_system_type
  }

  features {
    nesting = var.ct_feature_nesting
    fuse    = var.ct_feature_fuse
    keyctl  = local.feature_keyctl
    mount   = length(var.ct_feature_mount) > 0 ? var.ct_feature_mount : null
  }

  console {
    enabled   = var.ct_console.enabled
    type      = var.ct_console.type
    tty_count = var.ct_console.tty_count
  }

  cpu {
    architecture = var.ct_cpu_architecture
    cores        = var.ct_cpu_cores
    units        = var.ct_cpu_units
  }

  memory {
    dedicated = local.memory_dedicated
    swap      = var.ct_memory_swap
  }

  disk {
    datastore_id  = var.ct_disk_datastore_id
    size          = local.disk_size
    mount_options = var.ct_disk_mount_options
  }

  startup {
    order      = var.ct_startup_order
    up_delay   = var.ct_startup_up_delay
    down_delay = var.ct_startup_down_delay
  }

  tags = local.tags

  dynamic "mount_point" {
    for_each = var.ct_mount_points
    content {
      volume        = mount_point.value.volume
      path          = mount_point.value.path
      acl           = mount_point.value.acl
      backup        = mount_point.value.backup
      mount_options = mount_point.value.mount_options
      quota         = mount_point.value.quota
      read_only     = mount_point.value.read_only
      replicate     = mount_point.value.replicate
      shared        = mount_point.value.shared
      size          = mount_point.value.size
    }
  }

  dynamic "network_interface" {
    for_each = var.ct_network_interfaces
    content {
      name        = network_interface.value.name
      bridge      = network_interface.value.bridge
      enabled     = network_interface.value.enabled
      firewall    = network_interface.value.firewall
      mac_address = local.effective_mac_addresses[network_interface.key]
      mtu         = network_interface.value.mtu
      rate_limit  = network_interface.value.rate_limit
      vlan_id     = network_interface.value.vlan_id
    }
  }

  dynamic "device_passthrough" {
    for_each = local.device_passthrough
    content {
      path       = device_passthrough.value.path
      deny_write = device_passthrough.value.deny_write
      gid        = device_passthrough.value.gid
      mode       = device_passthrough.value.mode
      uid        = device_passthrough.value.uid
    }
  }

  initialization {
    hostname = var.ct_hostname

    dynamic "ip_config" {
      for_each = local.effective_ip_configs
      content {
        ipv4 {
          address = ip_config.value.ipv4_address
          gateway = ip_config.value.ipv4_gateway
        }
      }
    }

    dynamic "dns" {
      for_each = length(var.ct_dns_servers) > 0 ? [1] : []
      content {
        servers = var.ct_dns_servers
      }
    }

    user_account {
      keys     = var.ct_user_ssh_keys
      password = var.ct_user_password != "" ? var.ct_user_password : null
    }
  }

  timeout_create = var.ct_timeouts.create
  timeout_delete = var.ct_timeouts.delete
  timeout_update = var.ct_timeouts.update
  timeout_clone  = var.ct_timeouts.clone

  wait_for_ip {
    ipv4 = var.ct_wait_for_ip_ipv4
    ipv6 = var.ct_wait_for_ip_ipv6
  }

  lifecycle {
    ignore_changes = [tags]

    precondition {
      condition     = var.nvidia == null || !local.unprivileged
      error_message = "nvidia device passthrough requires ct_unprivileged = false."
    }
  }
}

resource "time_sleep" "wait_for_boot" {
  depends_on      = [proxmox_virtual_environment_container.lxc]
  create_duration = var.ct_ssh_wait_duration
}

resource "ssh_resource" "provisioner" {
  count = local.provisioner_script != "" ? 1 : 0

  depends_on = [time_sleep.wait_for_boot]

  host        = local.ssh_host
  user        = var.ssh_user
  private_key = var.ssh_private_key != "" ? var.ssh_private_key : null
  agent       = var.ssh_agent
  port        = var.ssh_port
  timeout     = var.ct_provisioner_timeout

  triggers = {
    script_content = local.provisioner_script
  }

  file {
    content     = replace(local.provisioner_script, "\r\n", "\n")
    destination = "/tmp/provisioner.sh"
    permissions = "0700"
  }

  commands = [
    "chmod +x /tmp/provisioner.sh",
    "bash /tmp/provisioner.sh"
  ]
}
