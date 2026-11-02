resource "proxmox_virtual_environment_download_file" "system_image_file" {
  content_type        = "iso"
  datastore_id        = var.datastore_id
  file_name           = var.image_file_name
  node_name           = var.node_name
  url                 = var.image_url
  checksum            = var.checksum
  checksum_algorithm  = var.checksum_algorithm
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_file" "user_config" {
  content_type = "snippets"
  datastore_id = var.datastore_id
  node_name    = var.node_name

  source_raw {
    data      = var.user_config_content
    file_name = var.user_config_filename
  }
}

resource "proxmox_virtual_environment_file" "vendor_config" {
  content_type = "snippets"
  datastore_id = var.datastore_id
  node_name    = var.node_name

  source_raw {
    data      = var.vendor_config_content
    file_name = var.vendor_config_filename
  }
}

resource "proxmox_virtual_environment_hardware_mapping_pci" "pcie_mapping" {
  for_each = { for mapping in var.pcie_hardware_mappings : mapping.name => mapping }

  name             = each.value.name
  comment          = each.value.comment
  mediated_devices = try(each.value.mediated_devices, false)
  map              = each.value.map
}

resource "proxmox_virtual_environment_vm" "vm" {
  depends_on = [
    proxmox_virtual_environment_file.user_config,
    proxmox_virtual_environment_file.vendor_config,
  ]

  name        = var.vm_name
  description = var.vm_description
  tags        = var.vm_tags
  node_name   = var.node_name
  vm_id       = var.vm_id

  machine         = var.vm_type
  bios            = var.vm_bios
  protection      = var.vm_protection
  stop_on_destroy = var.vm_stop_on_destroy

  agent {
    enabled = true
    timeout = var.vm_agent_timeout
  }

  operating_system {
    type = var.vm_os_type
  }

  cpu {
    cores   = var.vm_cores
    sockets = var.vm_sockets
    type    = var.vm_cpu_type
  }

  memory {
    dedicated = var.vm_memory_dedicated
    floating  = var.vm_memory_floating
  }

  disk {
    datastore_id = var.vm_disk_datastore_id
    file_id      = proxmox_virtual_environment_download_file.system_image_file.id
    size         = var.vm_disk_size
    interface    = var.vm_disk_interface
    discard      = var.vm_disk_discard
    ssd          = var.vm_disk_ssd
    cache        = var.vm_disk_cache
    file_format  = var.vm_disk_format
  }

  dynamic "efi_disk" {
    for_each = var.vm_bios == "ovmf" ? [1] : []
    content {
      datastore_id = var.vm_disk_datastore_id
      file_format  = "raw"
    }
  }

  dynamic "disk" {
    for_each = var.passthrough_disks
    content {
      datastore_id      = ""
      path_in_datastore = disk.value.path_in_datastore
      file_format       = disk.value.file_format
      interface         = disk.value.interface
      backup            = false
    }
  }

  dynamic "disk" {
    for_each = var.additional_disks
    content {
      datastore_id      = disk.value.datastore_id
      path_in_datastore = disk.value.path_in_datastore
      size              = disk.value.size
      file_format       = disk.value.file_format
      interface         = disk.value.interface
      discard           = disk.value.discard
      ssd               = disk.value.ssd
      cache             = disk.value.cache
      backup            = disk.value.backup
      replicate         = disk.value.replicate
    }
  }

  dynamic "hostpci" {
    for_each = var.pcie_devices
    content {
      device  = hostpci.value.device
      mapping = hostpci.value.mapping
      id      = hostpci.value.id
      pcie    = hostpci.value.pcie
      rombar  = hostpci.value.rombar
      xvga    = hostpci.value.xvga
    }
  }

  vga {
    type   = var.vm_vga_type
    memory = var.vm_vga_memory
  }

  network_device {
    bridge      = var.vm_network_bridge
    model       = var.vm_network_model
    mac_address = var.vm_network_mac_address
    vlan_id     = var.vm_network_vlan_id
  }

  startup {
    order      = var.vm_startup_order
    up_delay   = var.vm_startup_delay
    down_delay = var.vm_shutdown_delay
  }

  serial_device {}

  dynamic "watchdog" {
    for_each = var.vm_watchdog_enabled ? [1] : []
    content {
      enabled = var.vm_watchdog_enabled
      model   = var.vm_watchdog_model
      action  = var.vm_watchdog_action
    }
  }

  initialization {
    datastore_id = var.initialization_datastore_id
    interface    = var.vm_initialization_interface
    dns {
      servers = var.vm_dns_servers
    }
    ip_config {
      ipv4 {
        address = var.vm_ipv4_address
        gateway = var.vm_ipv4_address != "dhcp" ? var.vm_ipv4_gateway : null
      }
    }

    user_data_file_id   = proxmox_virtual_environment_file.user_config.id
    vendor_data_file_id = proxmox_virtual_environment_file.vendor_config.id
  }

  lifecycle {
    ignore_changes = [
      disk[0].file_id,
      tags
    ]
  }
}