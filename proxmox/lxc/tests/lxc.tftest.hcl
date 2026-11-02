mock_provider "proxmox" {}
mock_provider "ssh" {}
mock_provider "time" {}

variables {
  node_name                            = "pve"
  ct_hostname                          = "lxc-test"
  ct_operating_system_template_file_id = "local:vztmpl/debian-13.tar.zst"
}

run "mac_is_derived_from_hostname_and_interface" {
  command = plan

  variables {
    ct_network_interfaces = [{ name = "eth0" }, { name = "eth1" }]
  }

  assert {
    condition     = output.ct_mac_addresses["eth0"] == upper(format("BC:24:11:%s:%s:%s", substr(md5("lxc-test/eth0"), 0, 2), substr(md5("lxc-test/eth0"), 2, 2), substr(md5("lxc-test/eth0"), 4, 2)))
    error_message = "MAC must be BC:24:11 plus the first 3 bytes of md5(hostname/interface)."
  }

  assert {
    condition     = output.ct_mac_addresses["eth0"] != output.ct_mac_addresses["eth1"]
    error_message = "Interfaces of one container must not share a MAC."
  }
}

run "pinned_mac_wins" {
  command = plan

  variables {
    ct_network_interfaces = [{ name = "eth0", mac_address = "BC:24:11:00:00:01" }]
  }

  assert {
    condition     = output.ct_mac_addresses["eth0"] == "BC:24:11:00:00:01"
    error_message = "An explicit mac_address must be used verbatim."
  }
}

run "no_provisioner_by_default" {
  command = plan

  assert {
    condition     = length(ssh_resource.provisioner) == 0
    error_message = "No docker, nvidia or script means no ssh_resource."
  }

  assert {
    condition     = output.docker_host_ssh == null
    error_message = "docker_host_ssh must be null without docker."
  }
}

run "docker_enables_provisioner_and_tag" {
  command = plan

  variables {
    docker   = {}
    ssh_host = "192.168.1.10"
  }

  assert {
    condition     = length(ssh_resource.provisioner) == 1
    error_message = "docker = {} must create the provisioner."
  }

  assert {
    condition     = output.docker_host_ssh == "ssh://root@192.168.1.10:22"
    error_message = "docker_host_ssh must use ssh_host."
  }

  assert {
    condition     = contains(proxmox_virtual_environment_container.lxc.tags, "docker")
    error_message = "docker tag missing."
  }
}

run "nvidia_adds_devices_and_script" {
  command = plan

  variables {
    docker          = {}
    nvidia          = { driver_version = "580.142" }
    ct_unprivileged = false
  }

  assert {
    condition     = length(proxmox_virtual_environment_container.lxc.device_passthrough) == 6
    error_message = "Default NVIDIA device set should be passed through."
  }

  assert {
    condition     = strcontains(ssh_resource.provisioner[0].triggers.script_content, "580.142")
    error_message = "NVIDIA driver version must reach the install script."
  }
}

run "nvidia_requires_docker" {
  command = plan

  variables {
    nvidia          = { driver_version = "580.142" }
    ct_unprivileged = false
  }

  expect_failures = [var.nvidia]
}

run "nvidia_requires_privileged_container" {
  command = plan

  variables {
    docker          = {}
    nvidia          = { driver_version = "580.142" }
    ct_unprivileged = true
  }

  expect_failures = [proxmox_virtual_environment_container.lxc]
}

run "connection_bundles_the_fields_a_downstream_workspace_reads" {
  command = plan

  variables {
    docker   = {}
    ssh_host = "192.168.1.10"
  }

  assert {
    condition     = output.connection.hostname == "lxc-test" && output.connection.docker_host_ssh == "ssh://root@192.168.1.10:22"
    error_message = "connection must carry the hostname and the docker host string."
  }

  assert {
    condition     = output.connection.mac_addresses == output.ct_mac_addresses
    error_message = "connection.mac_addresses must match ct_mac_addresses."
  }
}

run "plain_container_keeps_small_defaults" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_container.lxc.memory[0].dedicated == 512 && proxmox_virtual_environment_container.lxc.disk[0].size == 8
    error_message = "A plain container defaults to 512 MB and 8 GB."
  }

  assert {
    condition     = proxmox_virtual_environment_container.lxc.features[0].keyctl == false && proxmox_virtual_environment_container.lxc.unprivileged == true
    error_message = "A plain container defaults to unprivileged without keyctl."
  }
}

run "docker_host_gets_the_old_wrapper_defaults" {
  command = plan

  variables {
    docker = {}
  }

  assert {
    condition     = proxmox_virtual_environment_container.lxc.memory[0].dedicated == 1024 && proxmox_virtual_environment_container.lxc.disk[0].size == 16
    error_message = "Docker hosts default to 1024 MB and 16 GB, as lxc_docker_host did."
  }

  assert {
    condition     = proxmox_virtual_environment_container.lxc.features[0].keyctl == true
    error_message = "Docker hosts need keyctl by default, as lxc_docker_host had it."
  }
}

run "explicit_values_beat_the_docker_defaults" {
  command = plan

  variables {
    docker              = {}
    ct_memory_dedicated = 4096
    ct_disk_size        = 64
    ct_feature_keyctl   = false
  }

  assert {
    condition     = proxmox_virtual_environment_container.lxc.memory[0].dedicated == 4096 && proxmox_virtual_environment_container.lxc.disk[0].size == 64 && proxmox_virtual_environment_container.lxc.features[0].keyctl == false
    error_message = "An explicit value must win over the docker default."
  }
}

run "nvidia_host_is_privileged_by_default" {
  command = plan

  variables {
    docker = {}
    nvidia = { driver_version = "580.142" }
  }

  assert {
    condition     = proxmox_virtual_environment_container.lxc.unprivileged == false
    error_message = "nvidia must default to a privileged container, as lxc_docker_nvidia_host did."
  }
}
