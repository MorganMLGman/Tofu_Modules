output "services" {
  description = "LAN addresses of the services in this stack"
  value = {
    @NAME@ = "${local.lxc.ip}@PORT_SUFFIX@"
  }
}
