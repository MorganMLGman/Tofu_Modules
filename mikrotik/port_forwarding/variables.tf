variable "comment" {
  description = "Comment for the port forwarding rule"
  type        = string

  validation {
    condition     = length(var.comment) > 0 && length(var.comment) <= 255
    error_message = "Comment must be between 1 and 255 characters."
  }
}

variable "internal_ip" {
  description = "Internal IP address to forward traffic to"
  type        = string

  validation {
    condition     = can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", var.internal_ip))
    error_message = "internal_ip must be a valid IPv4 address."
  }
}

variable "external_port" {
  description = "External port to forward from"
  type        = string

  validation {
    condition     = can(regex("^([0-9]{1,5}|[0-9]{1,5}-[0-9]{1,5})$", var.external_port))
    error_message = "external_port must be a valid port number (1-65535) or port range (e.g., 8000-8100)."
  }
}

variable "internal_port" {
  description = "Internal port to forward to"
  type        = string
  default     = null

  validation {
    condition     = var.internal_port == null || can(regex("^([0-9]{1,5}|[0-9]{1,5}-[0-9]{1,5})$", var.internal_port))
    error_message = "internal_port must be a valid port number (1-65535) or port range, or null."
  }
}

variable "protocol" {
  description = "Protocol for the port forwarding rule"
  type        = string
  default     = "tcp"

  validation {
    # RouterOS takes a single protocol per rule; "tcp,udp" passed here and
    # then failed at apply. Call the module twice for both.
    condition     = contains(["tcp", "udp"], var.protocol)
    error_message = "Protocol must be tcp or udp; call the module once per protocol for both."
  }
}

variable "wan_interface_list" {
  description = "WAN interface list name"
  type        = string
}

variable "enable_hairpin_nat" {
  description = "Enable hairpin NAT for LAN access to public IP."
  type        = bool
  default     = false
}

variable "lan_network" {
  description = "LAN network CIDR for hairpin NAT"
  type        = string
  default     = "192.168.1.0/24"

  validation {
    condition     = can(regex("^(\\d{1,3}\\.){3}\\d{1,3}/(\\d{1,2})$", var.lan_network))
    error_message = "lan_network must be a valid CIDR notation (e.g., 192.168.1.0/24)."
  }
}

variable "place_before" {
  description = "Before which position the rule will be inserted"
  type        = string
  default     = null
}
