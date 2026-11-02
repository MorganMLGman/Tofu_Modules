mock_provider "routeros" {}

variables {
  comment            = "web"
  internal_ip        = "192.168.1.10"
  external_port      = "8080"
  wan_interface_list = "WAN"
}

run "internal_port_defaults_to_external" {
  command = plan

  assert {
    condition     = routeros_ip_firewall_nat.port_forward.to_ports == "8080"
    error_message = "to_ports must fall back to external_port."
  }

  assert {
    condition     = routeros_ip_firewall_filter.allow_port_forward.dst_port == "8080"
    error_message = "The accept rule must match the internal port."
  }
}

run "internal_port_is_used_when_set" {
  command = plan

  variables {
    internal_port = "80"
  }

  assert {
    condition     = routeros_ip_firewall_nat.port_forward.to_ports == "80" && routeros_ip_firewall_filter.allow_port_forward.dst_port == "80"
    error_message = "NAT and filter must both use internal_port."
  }
}

run "hairpin_rules_only_when_enabled" {
  command = plan

  assert {
    condition     = length(routeros_ip_firewall_nat.hairpin_dstnat) == 0 && length(routeros_ip_firewall_nat.hairpin_srcnat) == 0
    error_message = "Hairpin NAT must be off by default."
  }
}

run "hairpin_dstnat_excludes_the_lan_itself" {
  command = plan

  variables {
    enable_hairpin_nat = true
    lan_network        = "192.168.1.0/24"
  }

  assert {
    condition     = length(routeros_ip_firewall_nat.hairpin_srcnat) == 1
    error_message = "Enabling hairpin must create the srcnat rule."
  }

  assert {
    condition     = routeros_ip_firewall_nat.hairpin_dstnat[0].dst_address == "!192.168.1.0/24" && routeros_ip_firewall_nat.hairpin_dstnat[0].dst_address_type == "local"
    error_message = "The hairpin dstnat must only match the router's own non-LAN addresses."
  }
}

run "combined_protocol_is_rejected" {
  command = plan

  variables {
    protocol = "tcp,udp"
  }

  expect_failures = [var.protocol]
}

run "malformed_port_is_rejected" {
  command = plan

  variables {
    external_port = "80a"
  }

  expect_failures = [var.external_port]
}
