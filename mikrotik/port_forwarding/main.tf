# ================================
# Port Forwarding DSTNAT Rule
# ================================

resource "routeros_ip_firewall_nat" "port_forward" {
  comment           = var.comment
  chain             = "dstnat"
  action            = "dst-nat"
  protocol          = var.protocol
  dst_port          = var.external_port
  in_interface_list = var.wan_interface_list
  to_addresses      = var.internal_ip
  to_ports          = var.internal_port != null ? var.internal_port : var.external_port
}

# ================================
# Firewall Filter Rule for Port Forwarding
# ================================

resource "routeros_ip_firewall_filter" "allow_port_forward" {
  comment     = "Allow ${var.comment}"
  chain       = "forward"
  action      = "accept"
  protocol    = var.protocol
  dst_port    = var.internal_port != null ? var.internal_port : var.external_port
  dst_address = var.internal_ip
  # Keyed on the NAT state, not the WAN list, so hairpinned LAN traffic is
  # accepted too once the forward chain ends in a drop.
  connection_nat_state = "dstnat"
  connection_state     = "new"
  place_before         = var.place_before
}

# ================================
# Hairpin NAT for LAN access to public IP
# ================================

resource "routeros_ip_firewall_nat" "hairpin_dstnat" {
  count = var.enable_hairpin_nat ? 1 : 0

  comment     = "Hairpin DSTNAT - ${var.comment}"
  chain       = "dstnat"
  action      = "dst-nat"
  protocol    = var.protocol
  dst_port    = var.external_port
  src_address = var.lan_network
  # The router's own non-LAN addresses: the dynamic public IP, but also tunnel
  # IPs. "!LAN" alone hijacked the port towards every remote host; "local"
  # alone would also capture the LAN IP, and with it management on 443/8291.
  # ponytail: tunnel IPs still match on this port; add an internal-networks
  # address list if a forwarded port ever collides with a router service there.
  dst_address_type = "local"
  dst_address      = "!${var.lan_network}"
  to_addresses     = var.internal_ip
  to_ports         = var.internal_port != null ? var.internal_port : var.external_port
}

resource "routeros_ip_firewall_nat" "hairpin_srcnat" {
  count = var.enable_hairpin_nat ? 1 : 0

  comment     = "Hairpin SRCNAT - ${var.comment}"
  chain       = "srcnat"
  action      = "masquerade"
  protocol    = var.protocol
  dst_port    = var.internal_port != null ? var.internal_port : var.external_port
  src_address = var.lan_network
  dst_address = var.internal_ip
}
