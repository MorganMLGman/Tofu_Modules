locals {
  all_device_passthrough = concat(
    [for d in var.nvidia_devices : { path = d, deny_write = null, gid = null, mode = null, uid = null }],
    var.ct_device_passthrough
  )
}

module "lxc_base" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//proxmox/lxc_base"

  node_name      = var.node_name
  ct_id          = var.ct_id
  ct_description = var.ct_description
  ct_hostname    = var.ct_hostname
  ct_tags        = var.ct_tags
  ct_extra_tags  = ["docker", "nvidia"]

  ct_unprivileged  = var.ct_unprivileged
  ct_protection    = var.ct_protection
  ct_started       = var.ct_started
  ct_start_on_boot = var.ct_start_on_boot

  ct_operating_system_template_file_id = var.ct_operating_system_template_file_id
  ct_operating_system_type             = var.ct_operating_system_type

  ct_cpu_architecture = var.ct_cpu_architecture
  ct_cpu_cores        = var.ct_cpu_cores
  ct_cpu_units        = var.ct_cpu_units

  ct_memory_dedicated = var.ct_memory_dedicated
  ct_memory_swap      = var.ct_memory_swap

  ct_disk_datastore_id  = var.ct_disk_datastore_id
  ct_disk_size          = var.ct_disk_size
  ct_disk_mount_options = var.ct_disk_mount_options

  ct_feature_nesting = var.ct_feature_nesting
  ct_feature_fuse    = var.ct_feature_fuse
  ct_feature_keyctl  = var.ct_feature_keyctl
  ct_feature_mount   = var.ct_feature_mount

  ct_console = var.ct_console

  ct_network_interfaces = var.ct_network_interfaces
  ct_ipv4_address       = var.ct_ipv4_address
  ct_ipv4_gateway       = var.ct_ipv4_gateway
  ct_ip_configs         = var.ct_ip_configs
  ct_dns_servers        = var.ct_dns_servers

  ct_user_ssh_keys = var.ct_user_ssh_keys
  ct_user_password = var.ct_user_password

  ct_mount_points = var.ct_mount_points
  # NVIDIA devices are merged with user-supplied passthrough entries here.
  ct_device_passthrough = local.all_device_passthrough

  ct_startup_order      = var.ct_startup_order
  ct_startup_up_delay   = var.ct_startup_up_delay
  ct_startup_down_delay = var.ct_startup_down_delay

  ct_timeouts          = var.ct_timeouts
  ct_wait_for_ip_ipv4  = var.ct_wait_for_ip_ipv4
  ct_wait_for_ip_ipv6  = var.ct_wait_for_ip_ipv6
  ct_ssh_wait_duration = var.ct_ssh_wait_duration

  # Docker/NVIDIA install scripts are idempotent; changes re-run without destroying the container.
  replace_trigger_value = ""
}
