# Port Forwarding Module

Manages port forwarding rules with DSTNAT and firewall filter rules in MikroTik RouterOS.

## Usage

```hcl
module "mqtt_forward" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//mikrotik/port_forwarding"
  
  comment             = "MQTT Port Forwarding"
  internal_ip         = "192.168.1.200"
  external_port       = "1883"
  internal_port       = "1883"
  protocol            = "tcp"
  wan_interface_list  = routeros_interface_list.wan.name
}
```

With hairpin NAT:

```hcl
module "web_forward" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//mikrotik/port_forwarding"
  
  comment             = "Web Server"
  internal_ip         = "192.168.1.100"
  external_port       = "80"
  internal_port       = "80"
  protocol            = "tcp"
  wan_interface_list  = routeros_interface_list.wan.name
  enable_hairpin_nat  = true
  lan_network         = "192.168.1.0/24"
}
```

## Inputs

- **comment** - Rule description (required)
- **internal_ip** - Internal server IP (required)
- **external_port** - External port (required)
- **internal_port** - Internal port (default: external_port)
- **protocol** - Protocol: tcp or udp (default: tcp); for both, call the module once per protocol
- **wan_interface_list** - WAN interface list name (required)
- **enable_hairpin_nat** - Enable NAT loopback (default: false)
- **lan_network** - LAN network CIDR (default: 192.168.1.0/24)
- **place_before** - Filter rule ID to insert the accept rule before (default: null, appended to the end of the forward chain)

## Outputs

- **nat_rule_id** - Created NAT rule ID
- **filter_rule_id** - Created firewall filter rule ID
- **forwarded_address** - Internal IP address
- **forwarded_port** - Internal port
