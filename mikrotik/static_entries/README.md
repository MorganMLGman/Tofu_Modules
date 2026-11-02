# Static Entries Module

Manages static DHCP leases and DNS entries for devices in MikroTik RouterOS.

## Usage

```hcl
module "static_entries" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//mikrotik/static_entries"

  dhcp_server_name = "dhcp-server"

  static_entries = {
    "Server" = {
      mac_address = "aa:bb:cc:dd:ee:ff"
      ip_address  = "192.168.1.10"
      comment     = "Main server"
    }
    "Printer" = {
      mac_address = "11:22:33:44:55:66"
      ip_address  = "192.168.1.12"
      comment     = "Office printer"
    }
  }
}
```

## Inputs

- **dhcp_server_name** - Name of the DHCP server
- **static_entries** - Map of devices with `mac_address`, `ip_address`, and `comment`

## Outputs

- **dhcp_lease_ids** - IDs of created DHCP leases
- **dns_static_ids** - IDs of created DNS static entries
