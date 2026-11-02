# --- Node ---

variable "node_name" {
  description = "Proxmox node name where the container will be deployed"
  type        = string
}

# --- Container identity ---

variable "ct_id" {
  description = "Container ID. If not specified, Proxmox will auto-assign."
  type        = number
  default     = null
}

variable "ct_description" {
  description = "Description of the container"
  type        = string
  default     = ""
}

variable "ct_hostname" {
  description = "Hostname for the container"
  type        = string
}

variable "ct_tags" {
  description = "Tags for the container (tofu, ci, and docker are auto-appended)"
  type        = list(string)
  default     = []
}

# --- Container behavior ---

variable "ct_unprivileged" {
  description = "Run the container as unprivileged"
  type        = bool
  default     = true
}

variable "ct_protection" {
  description = "Enable protection to prevent container removal"
  type        = bool
  default     = false
}

variable "ct_started" {
  description = "Start the container after creation"
  type        = bool
  default     = true
}

variable "ct_start_on_boot" {
  description = "Start the container when Proxmox boots"
  type        = bool
  default     = true
}

# --- Operating system ---

variable "ct_operating_system_template_file_id" {
  description = "Template file ID for the container OS (e.g. local:vztmpl/ubuntu-24.04-standard_24.04-1_amd64.tar.zst)"
  type        = string
}

variable "ct_operating_system_type" {
  description = "Operating system type"
  type        = string
  default     = "ubuntu"

  validation {
    condition     = contains(["alpine", "archlinux", "centos", "debian", "devuan", "fedora", "gentoo", "nixos", "opensuse", "ubuntu", "unmanaged"], var.ct_operating_system_type)
    error_message = "ct_operating_system_type must be one of: alpine, archlinux, centos, debian, devuan, fedora, gentoo, nixos, opensuse, ubuntu, unmanaged."
  }
}

# --- CPU ---

variable "ct_cpu_architecture" {
  description = "CPU architecture"
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64", "armhf", "i386"], var.ct_cpu_architecture)
    error_message = "ct_cpu_architecture must be one of: amd64, arm64, armhf, i386."
  }
}

variable "ct_cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 1
}

variable "ct_cpu_units" {
  description = "CPU units (weight for scheduler)"
  type        = number
  default     = 1024
}

# --- Memory ---

variable "ct_memory_dedicated" {
  description = "Dedicated memory in MB"
  type        = number
  default     = 1024
}

variable "ct_memory_swap" {
  description = "Swap size in MB"
  type        = number
  default     = 512
}

# --- Disk ---

variable "ct_disk_datastore_id" {
  description = "Datastore ID for the root filesystem"
  type        = string
  default     = "local-lvm"
}

variable "ct_disk_size" {
  description = "Root filesystem size in GB"
  type        = number
  default     = 16
}

variable "ct_disk_mount_options" {
  description = "Mount options for the root filesystem"
  type        = list(string)
  default     = []
}

# --- Features ---

variable "ct_feature_nesting" {
  description = "Enable nested containers/VMs (required for Docker)"
  type        = bool
  default     = true
}

variable "ct_feature_fuse" {
  description = "Enable FUSE filesystem support"
  type        = bool
  default     = false
}

variable "ct_feature_keyctl" {
  description = "Enable keyctl system calls (required for Docker in LXC)"
  type        = bool
  default     = true
}

variable "ct_feature_mount" {
  description = "Allowed mount types (e.g. [\"nfs\", \"fuse\"])"
  type        = list(string)
  default     = []
}

# --- Console ---

variable "ct_console" {
  description = "Console configuration"
  type = object({
    enabled   = optional(bool, true)
    type      = optional(string, "shell")
    tty_count = optional(number, 2)
  })
  default = {}
}

# --- Network ---

variable "ct_network_interfaces" {
  description = "List of network interfaces for the container"
  type = list(object({
    name        = optional(string, "eth0")
    bridge      = optional(string, "vmbr0")
    enabled     = optional(bool, true)
    firewall    = optional(bool, false)
    mac_address = optional(string)
    mtu         = optional(number)
    rate_limit  = optional(number)
    vlan_id     = optional(number)
  }))
  default = [{}]
}

variable "ct_ipv4_address" {
  description = "IPv4 address in CIDR notation or 'dhcp'"
  type        = string
  default     = "dhcp"

  validation {
    condition     = var.ct_ipv4_address == "dhcp" || can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/\\d{1,2}$", var.ct_ipv4_address))
    error_message = "ct_ipv4_address must be 'dhcp' or a valid IPv4 CIDR notation (e.g., 192.168.1.10/24)."
  }
}

variable "ct_ipv4_gateway" {
  description = "IPv4 gateway address. Defaults to first usable IP in the subnet (e.g. x.x.x.1) when using static IP, or null for DHCP."
  type        = string
  default     = null
}

variable "ct_ip_configs" {
  description = "List of IP configurations, one per network interface (positional). When set, overrides ct_ipv4_address/ct_ipv4_gateway."
  type = list(object({
    ipv4_address = optional(string, "dhcp")
    ipv4_gateway = optional(string)
  }))
  default = []
}

variable "ct_dns_servers" {
  description = "List of DNS server addresses. Empty list uses DHCP-provided DNS or no explicit DNS."
  type        = list(string)
  default     = []
}

# --- User account ---

variable "ct_user_ssh_keys" {
  description = "SSH public keys for the root user account"
  type        = list(string)
  default     = []
}

variable "ct_user_password" {
  description = "Password for the root user account"
  type        = string
  default     = ""
  sensitive   = true
}

# --- Mount points ---

variable "ct_mount_points" {
  description = "List of mount points for the container"
  type = list(object({
    volume        = string
    path          = string
    acl           = optional(bool)
    backup        = optional(bool)
    mount_options = optional(list(string))
    quota         = optional(bool)
    read_only     = optional(bool)
    replicate     = optional(bool)
    shared        = optional(bool)
    size          = optional(string)
  }))
  default = []
}

# --- Device passthrough ---

variable "ct_device_passthrough" {
  description = "List of devices to pass through to the container"
  type = list(object({
    path       = string
    deny_write = optional(bool)
    gid        = optional(number)
    mode       = optional(string)
    uid        = optional(number)
  }))
  default = []
}

# --- Startup ---

variable "ct_startup_order" {
  description = "Container startup order"
  type        = number
  default     = 1
}

variable "ct_startup_up_delay" {
  description = "Delay in seconds after container starts before next boot"
  type        = number
  default     = 0
}

variable "ct_startup_down_delay" {
  description = "Delay in seconds when stopping containers"
  type        = number
  default     = 0
}

# --- Timeouts ---

variable "ct_timeouts" {
  description = "Timeout values for container operations (in seconds)"
  type = object({
    create = optional(number, 1800)
    delete = optional(number, 60)
    update = optional(number, 1800)
    clone  = optional(number, 1800)
  })
  default = {}
}

# --- Wait for IP ---

variable "ct_wait_for_ip_ipv4" {
  description = "Wait for IPv4 address before considering container created"
  type        = bool
  default     = true
}

variable "ct_wait_for_ip_ipv6" {
  description = "Wait for IPv6 address before considering container created"
  type        = bool
  default     = false
}

# --- SSH connection ---

variable "ssh_user" {
  description = "SSH user for provisioner connections"
  type        = string
  default     = "root"
}

variable "ssh_private_key" {
  description = "SSH private key content (PEM format) for provisioner connections. Leave empty to use ssh-agent."
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_agent" {
  description = "Use ssh-agent for authentication"
  type        = bool
  default     = true
}

variable "ssh_port" {
  description = "SSH port for provisioner connections"
  type        = number
  default     = 22
}

variable "ct_provisioner_timeout" {
  description = "Timeout for the SSH provisioner operation (e.g. 5m, 300s)"
  type        = string
  default     = "5m"
}

variable "ct_ssh_wait_duration" {
  description = "Duration to wait after container creation before attempting SSH provisioning (e.g. 15s, 30s)"
  type        = string
  default     = "15s"
}

# --- Docker configuration ---

variable "docker_install_compose" {
  description = "Install docker-compose plugin alongside Docker CE"
  type        = bool
  default     = true
}

variable "docker_daemon_config" {
  description = "Custom Docker daemon.json content as a JSON string. Empty string uses Docker defaults."
  type        = string
  default     = <<-EOT
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOT
}

variable "docker_enable_tcp" {
  description = "Expose Docker daemon on a TCP port (in addition to the default Unix socket)"
  type        = bool
  default     = false
}

variable "docker_tcp_port" {
  description = "TCP port for Docker daemon when docker_enable_tcp is true"
  type        = number
  default     = 2376
}

variable "ct_additional_provisioner_script_content" {
  description = "Additional provisioner script content to execute after Docker installation. Empty string disables additional provisioning. Changes will NOT trigger LXC replacement."
  type        = string
  default     = ""
}
