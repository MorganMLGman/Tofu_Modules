# State migration from lxc_docker_host / lxc_docker_nvidia_host / lxc_ssh_provisioned,
# which nested this logic under module.lxc_base.
moved {
  from = module.lxc_base.proxmox_virtual_environment_container.lxc
  to   = proxmox_virtual_environment_container.lxc
}

moved {
  from = module.lxc_base.time_sleep.wait_for_boot
  to   = time_sleep.wait_for_boot
}

moved {
  from = ssh_resource.docker_install
  to   = ssh_resource.provisioner[0]
}
