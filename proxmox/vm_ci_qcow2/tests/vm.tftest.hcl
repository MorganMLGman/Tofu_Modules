# Only input validation is covered: outputs.tf reads proxmox_virtual_environment_vm.vm.started,
# which a mock provider cannot set, so any run that evaluates outputs fails.
mock_provider "proxmox" {}

variables {
  image_url             = "https://example.com/image.img"
  node_name             = "pve"
  image_file_name       = "image.img"
  checksum              = "abc"
  user_config_content   = "#cloud-config"
  vendor_config_content = "#cloud-config"
  vm_name               = "vm-test"
  vm_description        = "test"
  vm_tags               = ["test"]
}

run "invalid_bios_is_rejected" {
  command = plan

  variables {
    vm_bios = "grub"
  }

  expect_failures = [var.vm_bios]
}

run "invalid_ipv4_is_rejected" {
  command = plan

  variables {
    vm_ipv4_address = "192.168.1.10"
  }

  expect_failures = [var.vm_ipv4_address]
}
