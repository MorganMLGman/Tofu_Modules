variable "static_entries" {
  description = "Map of static entries with keys as device names and values as maps containing mac_address, ip_address, comment, and optional address_lists."
  type = map(object({
    mac_address   = string
    ip_address    = string
    comment       = string
    address_lists = optional(string, "")
  }))

  validation {
    condition = alltrue([
      for k, v in var.static_entries : (
        can(regex("^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$", v.mac_address)) &&
        can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", v.ip_address)) &&
        length(v.comment) > 0 && length(v.comment) <= 255 &&
        can(regex("^[a-z0-9-]+$", k)) &&
        length(k) <= 63
      )
    ])
    error_message = "MAC address must be valid (XX:XX:XX:XX:XX:XX or XX-XX-XX-XX-XX-XX), IP address must be valid IPv4, comment must be 1-255 chars, and device name must be lowercase alphanumeric with hyphens (max 63 chars)."
  }
}

variable "dhcp_server_name" {
  description = "Name of the DHCP server to associate static leases with."
  type        = string

  validation {
    condition     = length(var.dhcp_server_name) > 0 && length(var.dhcp_server_name) <= 80
    error_message = "DHCP server name must be between 1 and 80 characters."
  }
}
