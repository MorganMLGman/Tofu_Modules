locals {
  docker_install_script = templatefile("${path.module}/scripts/install_docker.sh", {
    docker_daemon_config = var.docker_daemon_config
    docker_compose       = var.docker_install_compose
    docker_enable_tcp    = var.docker_enable_tcp
    docker_tcp_port      = var.docker_tcp_port
  })

  full_provisioner_script = join("\n", compact([
    local.docker_install_script,
    var.ct_additional_provisioner_script_content
  ]))
}

resource "ssh_resource" "docker_install" {
  depends_on = [module.lxc_base]

  host        = module.lxc_base.ct_ipv4_address
  user        = var.ssh_user
  private_key = var.ssh_private_key != "" ? var.ssh_private_key : null
  agent       = var.ssh_agent
  port        = var.ssh_port
  timeout     = var.ct_provisioner_timeout

  triggers = {
    script_content = local.full_provisioner_script
  }

  file {
    content     = replace(local.full_provisioner_script, "\r\n", "\n")
    destination = "/tmp/docker_install.sh"
    permissions = "0700"
  }

  commands = [
    "chmod +x /tmp/docker_install.sh",
    "bash /tmp/docker_install.sh"
  ]
}
