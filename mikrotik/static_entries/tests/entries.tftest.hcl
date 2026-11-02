mock_provider "routeros" {}

variables {
  dhcp_server_name = "dhcp1"
}

run "lease_and_dns_record_per_entry" {
  command = plan

  variables {
    static_entries = {
      "lxc-a" = { mac_address = "BC:24:11:00:00:01", ip_address = "192.168.1.10", comment = "A" }
      "lxc-b" = { mac_address = "BC:24:11:00:00:02", ip_address = "192.168.1.11", comment = "B", address_lists = "no-internet" }
    }
  }

  assert {
    condition     = length(routeros_ip_dhcp_server_lease.static_lease) == 2 && routeros_ip_dns_record.static_dns["lxc-a"].name == "lxc-a.lan"
    error_message = "Each entry needs a lease and a <name>.lan record."
  }

  assert {
    condition     = routeros_ip_dhcp_server_lease.static_lease["lxc-a"].address_lists == null
    error_message = "An empty address_lists must be sent as null."
  }

  assert {
    condition     = routeros_ip_dhcp_server_lease.static_lease["lxc-b"].address_lists == "no-internet"
    error_message = "address_lists must reach the lease."
  }
}

run "malformed_mac_is_rejected" {
  command = plan

  variables {
    static_entries = {
      "lxc-a" = { mac_address = "not-a-mac", ip_address = "192.168.1.10", comment = "A" }
    }
  }

  expect_failures = [var.static_entries]
}

run "uppercase_device_name_is_rejected" {
  command = plan

  variables {
    static_entries = {
      "LXC_A" = { mac_address = "BC:24:11:00:00:01", ip_address = "192.168.1.10", comment = "A" }
    }
  }

  expect_failures = [var.static_entries]
}
