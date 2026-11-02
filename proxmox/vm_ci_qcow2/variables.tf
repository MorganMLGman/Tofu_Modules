variable "image_url" {
  description = "URL to download the QCOW2 file"
  type        = string
}

variable "datastore_id" {
  description = "Datastore ID to store the ISO file"
  type        = string
  default     = "local"
}

variable "node_name" {
  description = "Node name to download the ISO file"
  type        = string
}

variable "image_file_name" {
  description = "Name of the file to be saved"
  type        = string

}

variable "checksum" {
  description = "Checksum of the file"
  type        = string
}

variable "checksum_algorithm" {
  description = "Checksum algorithm"
  type        = string
  default     = "sha256"
}

variable "user_config_filename" {
  type        = string
  default     = "user-config.yaml.tpl"
  description = "The name of the user-data configuration file for cloud-init, uploaded to Proxmox."

}

variable "user_config_content" {
  type        = string
  description = "Content of the user-config cloud-init file"
}

variable "vendor_config_filename" {
  type        = string
  default     = "vendor-config.yaml.tpl"
  description = "The name of the vendor-data configuration file for cloud-init, uploaded to Proxmox."

}

variable "vendor_config_content" {
  type        = string
  description = "Content of the vendor-config cloud-init file"
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_description" {
  description = "Description of the VM"
  type        = string
}

variable "vm_tags" {
  description = "Tags of the VM"
  type        = list(string)
}

variable "vm_type" {
  description = "Type of the VM"
  type        = string
  default     = "q35"
}

variable "vm_bios" {
  description = "BIOS of the VM (seabios or ovmf)"
  type        = string
  default     = "seabios"

  validation {
    condition     = contains(["seabios", "ovmf"], var.vm_bios)
    error_message = "vm_bios must be either 'seabios' or 'ovmf'."
  }
}

variable "vm_os_type" {
  description = "Type of the OS"
  type        = string
  default     = "l26"
}

variable "vm_cores" {
  description = "Number of cores"
  type        = number
  default     = 1
}

variable "vm_sockets" {
  description = "Number of sockets"
  type        = number
  default     = 1
}

variable "vm_cpu_type" {
  description = "Type of the CPU"
  type        = string
  default     = "x86-64-v2-AES"
}

variable "vm_memory_dedicated" {
  description = "Dedicated memory"
  type        = number
  default     = 1024
}

variable "vm_memory_floating" {
  description = "Floating memory"
  type        = number
  default     = 1024
}

variable "vm_disk_datastore_id" {
  description = "Datastore ID to store the VM disk"
  type        = string
  default     = "local"
}

variable "vm_disk_size" {
  description = "Size of the disk"
  type        = number
  default     = 32
}

variable "vm_disk_interface" {
  description = "Interface of the disk"
  type        = string
  default     = "scsi0"
}

variable "vm_disk_discard" {
  description = "Discard of the disk"
  type        = string
  default     = "on"
}

variable "vm_disk_ssd" {
  description = "SSD of the disk"
  type        = bool
  default     = false
}

variable "vm_disk_cache" {
  description = "Cache of the disk"
  type        = string
  default     = "writeback"
}

variable "vm_disk_format" {
  description = "Format of the disk"
  type        = string
  default     = "raw"

}

variable "vm_network_bridge" {
  description = "Bridge of the network"
  type        = string
  default     = "vmbr0"
}

variable "vm_network_model" {
  description = "Model of the network"
  type        = string
  default     = "virtio"
}

variable "vm_network_mac_address" {
  description = "MAC address for the VM network interface"
  type        = string
  default     = ""
}
variable "vm_network_vlan_id" {
  description = "VLAN ID for the VM network interfaces"
  type        = number
  default     = null
}

variable "vm_startup_order" {
  description = "Startup order of the VM"
  type        = number
  default     = 1
}

variable "vm_startup_delay" {
  description = "Startup delay of the VM"
  type        = number
  default     = 0
}

variable "vm_shutdown_delay" {
  description = "Shutdown delay of the VM"
  type        = number
  default     = 0
}

variable "vm_ipv4_address" {
  description = "IPv4 address of the VM in CIDR notation or 'dhcp' for auto-discovery"
  type        = string
  default     = "dhcp"

  validation {
    condition     = var.vm_ipv4_address == "dhcp" || can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/\\d{1,2}$", var.vm_ipv4_address))
    error_message = "vm_ipv4_address must be 'dhcp' or a valid IPv4 CIDR notation (e.g., 192.168.1.10/24)."
  }
}

variable "vm_ipv4_gateway" {
  type        = string
  default     = "192.168.1.1"
  description = "IPv4 gateway address"
}

variable "vm_dns_servers" {
  type    = list(string)
  default = ["192.168.1.254", "192.168.2.254"]
}

variable "vm_initialization_interface" {
  description = "Hardware interface for cloud-init disk"
  type        = string
  default     = "sata2"
}

variable "additional_disks" {
  description = "List of additional disks to attach to the VM"
  type = list(object({
    datastore_id      = string
    size              = optional(number, 10)
    path_in_datastore = optional(string)
    file_format       = optional(string, "raw")
    interface         = optional(string, "scsi1")
    discard           = optional(string, "ignore")
    ssd               = optional(bool, false)
    cache             = optional(string, "none")
    backup            = optional(bool, false)
    replicate         = optional(bool, false)
  }))
  default = []
}

variable "passthrough_disks" {
  description = "List of physical disks to pass through to the VM (e.g., /dev/sda, /dev/sdb)"
  type = list(object({
    path_in_datastore = string
    file_format       = optional(string, "raw")
    interface         = optional(string, "scsi1")
  }))
  default = []
}

variable "vm_id" {
  description = "The unique VM identifier. If not specified, Proxmox will auto-assign."
  type        = number
  default     = null
}

variable "vm_protection" {
  description = "Enable protection to disable VM removal and disk operations"
  type        = bool
  default     = false
}

variable "vm_stop_on_destroy" {
  description = "Stop rather than shutdown VM on destroy"
  type        = bool
  default     = false
}

variable "vm_agent_timeout" {
  description = "Timeout for QEMU agent operations"
  type        = string
  default     = "15m"
}

variable "initialization_datastore_id" {
  description = "Datastore ID for cloud-init disk (defaults to local-lvm)"
  type        = string
  default     = "local-lvm"
}

variable "pcie_devices" {
  description = "List of PCIe devices to attach to the VM. Use either 'mapping' for cluster-wide resource mapping or 'id' for specific device ID."
  type = list(object({
    device  = string                # hostpci0, hostpci1, etc.
    mapping = optional(string)      # Resource mapping name
    id      = optional(string)      # PCI device ID (e.g., 8086:5916)
    pcie    = optional(bool, true)  # Use PCIe instead of PCI
    rombar  = optional(bool, true)  # Make firmware ROM visible
    xvga    = optional(bool, false) # Mark as primary GPU
  }))
  default = []
}

variable "pcie_hardware_mappings" {
  description = "PCIe hardware mappings to create at cluster level. Enables resource mapping for devices."
  type = list(object({
    name             = string                # Mapping name (e.g., 'gpu', 'nic')
    comment          = optional(string)      # Description of the mapping
    mediated_devices = optional(bool, false) # Enable mediated devices
    map = list(object({
      node         = string           # Node name where device is located
      path         = string           # PCI path (e.g., "0000:00:02.0")
      id           = string           # Device ID (e.g., "8086:5916")
      comment      = optional(string) # Device-specific comment
      iommu_group  = optional(number) # IOMMU group number
      subsystem_id = optional(string) # Subsystem ID (e.g., "8086:2068")
    }))
  }))
  default = []
}

variable "vm_vga_type" {
  description = "VGA type for the VM"
  type        = string
  default     = "std"

  validation {
    condition     = contains(["cirrus", "none", "qxl", "qxl2", "qxl3", "qxl4", "serial0", "serial1", "serial2", "serial3", "std", "virtio", "virtio-gl", "vmware"], var.vm_vga_type)
    error_message = "vm_vga_type must be a valid VGA type."
  }
}

variable "vm_vga_memory" {
  description = "VGA memory in megabytes"
  type        = number
  default     = 16
}

variable "vm_watchdog_enabled" {
  description = "Enable watchdog device for the VM"
  type        = bool
  default     = false
}

variable "vm_watchdog_model" {
  description = "Watchdog model/type (i6300esb or ib700)"
  type        = string
  default     = "i6300esb"

  validation {
    condition     = contains(["i6300esb", "ib700"], var.vm_watchdog_model)
    error_message = "vm_watchdog_model must be either 'i6300esb' or 'ib700'."
  }
}

variable "vm_watchdog_action" {
  description = "Watchdog action when timeout occurs (debug, none, pause, poweroff, reset, shutdown)"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["debug", "none", "pause", "poweroff", "reset", "shutdown"], var.vm_watchdog_action)
    error_message = "vm_watchdog_action must be one of: debug, none, pause, poweroff, reset, shutdown."
  }
}