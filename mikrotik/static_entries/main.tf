resource "routeros_ip_dhcp_server_lease" "static_lease" {
  for_each      = var.static_entries
  server        = var.dhcp_server_name
  address       = each.value.ip_address
  mac_address   = each.value.mac_address
  comment       = each.value.comment
  address_lists = each.value.address_lists != "" ? each.value.address_lists : null
}

resource "routeros_ip_dns_record" "static_dns" {
  for_each = var.static_entries
  name     = "${each.key}.lan"
  address  = each.value.ip_address
  comment  = each.value.comment
  type     = "A"
}
