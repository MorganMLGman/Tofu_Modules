# vm_ci_qcow2 - Terraform Module for Creating Virtual Machines in Proxmox

Terraform module for creating and managing virtual machines in Proxmox based on QCOW2 images with cloud-init support.

## Description

This module enables deploying virtual machines in Proxmox environment using:
- Download and management of ISO/QCOW2 images
- System initialization via cloud-init (user-data and vendor-data)
- Advanced hardware configuration (CPU, RAM, disks, network)
- Physical disk passthrough
- Dynamic addition of extra disks

## Requirements

- Terraform >= 1.0
- Proxmox VE 7.x or higher
- Terraform provider: `bpg/proxmox` version ~> 0.87.0

## Inputs (Variables)

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `image_url` | `string` | URL to download the QCOW2 file |
| `node_name` | `string` | Proxmox node name |
| `image_file_name` | `string` | Name of the file to save |
| `checksum` | `string` | Checksum of the file |
| `user_config_content` | `string` | Cloud-init user-data content |
| `vendor_config_content` | `string` | Cloud-init vendor-data content |
| `vm_name` | `string` | Virtual machine name |
| `vm_description` | `string` | Virtual machine description |
| `vm_tags` | `list(string)` | Tags assigned to the VM |

### Optional

#### Datastore and Network
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `datastore_id` | `string` | `"local"` | Datastore ID for storing the image |
| `vm_disk_datastore_id` | `string` | `"local"` | Datastore ID for VM disk |
| `initialization_datastore_id` | `string` | `"local-lvm"` | Datastore ID for cloud-init disk |
| `vm_network_bridge` | `string` | `"vmbr0"` | Network bridge |
| `vm_network_model` | `string` | `"virtio"` | Network interface model |

#### CPU and Memory
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vm_cores` | `number` | `1` | Number of cores |
| `vm_sockets` | `number` | `1` | Number of CPU sockets |
| `vm_cpu_type` | `string` | `"x86-64-v2-AES"` | CPU type |
| `vm_memory_dedicated` | `number` | `1024` | Dedicated memory (MB) |
| `vm_memory_floating` | `number` | `1024` | Floating memory (MB) |

#### Disk
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vm_disk_size` | `number` | `32` | Disk size (GB) |
| `vm_disk_interface` | `string` | `"scsi0"` | Disk interface |
| `vm_disk_discard` | `string` | `"on"` | DISCARD options |
| `vm_disk_ssd` | `bool` | `false` | Whether disk is SSD |
| `vm_disk_cache` | `string` | `"writeback"` | Cache strategy |
| `vm_disk_format` | `string` | `"raw"` | Disk format |
| `additional_disks` | `list(object)` | `[]` | List of additional disks |
| `passthrough_disks` | `list(object)` | `[]` | Physical disks to passthrough |

#### Network Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vm_ipv4_address` | `string` | `"dhcp"` | IPv4 address in CIDR notation or 'dhcp' |
| `vm_ipv4_gateway` | `string` | `"192.168.1.1"` | IPv4 gateway |
| `vm_dns_servers` | `list(string)` | `["192.168.1.254", "192.168.2.254"]` | DNS servers |

#### BIOS and VM Type
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vm_type` | `string` | `"q35"` | Machine type |
| `vm_bios` | `string` | `"seabios"` | BIOS (seabios/ovmf) |
| `vm_os_type` | `string` | `"l26"` | Operating system type |

#### PCIe Device Passthrough
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `pcie_devices` | `list(object)` | `[]` | List of PCIe devices to attach to the VM |

#### Other
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vm_id` | `number` | `null` | VM ID (auto-assigned if null) |
| `vm_protection` | `bool` | `false` | Enable deletion protection |
| `vm_stop_on_destroy` | `bool` | `false` | Stop instead of shutdown |
| `vm_agent_timeout` | `string` | `"15m"` | Timeout for QEMU agent |
| `vm_startup_order` | `number` | `1` | VM startup order |
| `vm_startup_delay` | `number` | `0` | Startup delay (s) |
| `vm_shutdown_delay` | `number` | `0` | Shutdown delay (s) |
| `checksum_algorithm` | `string` | `"sha256"` | Checksum algorithm |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `vm_id` | `number` | Unique VM identifier |
| `vm_name` | `string` | Virtual machine name |
| `vm_ipv4_addresses` | `list(string)` | All IPv4 addresses |
| `vm_ipv4_address` | `list(string)` | IPv4 addresses in 192.x.x.x network |
| `vm_ipv4_address_tailscale` | `list(string)` | Tailscale IPv4 addresses (100.x.x.x) |
| `vm_ipv6_addresses` | `list(string)` | All IPv6 addresses |
| `vm_mac_addresses` | `list(string)` | MAC addresses of network interfaces |
| `vm_network_interface_names` | `list(string)` | Network interface names |
| `vm_status` | `string` | VM status (running/stopped) |
| `vm_node_name` | `string` | Node name where VM is running |
| `pcie_mappings` | `map(string)` | Created PCIe hardware mapping IDs |
| `vm_status` | `string` | VM status (running/stopped) |
| `vm_node_name` | `string` | Node name where VM is running |

## Usage Examples

### Basic Example

```hcl
module "ci_vm" {
  source = "./vm_ci_qcow2"

  # Image
  image_url       = "https://cloud.debian.org/images/cloud/bookworm/daily/20240101-1234/debian-12-genericcloud-amd64-daily-20240101-1234.qcow2"
  image_file_name = "debian-12-ci.qcow2"
  checksum        = "abc123def456..."
  checksum_algorithm = "sha256"

  # Node and datastore
  node_name   = "pve-node1"
  datastore_id = "local"

  # Cloud-init
  user_config_content = base64decode(base64gzip(file("${path.module}/user-data.yaml")))
  vendor_config_content = base64decode(base64gzip(file("${path.module}/vendor-data.yaml")))

  # VM
  vm_name        = "ci-runner-01"
  vm_description = "CI/CD Pipeline Runner"
  vm_tags        = ["ci", "runner", "automation"]

  # Resources
  vm_cores               = 4
  vm_sockets             = 1
  vm_memory_dedicated    = 4096
  vm_memory_floating     = 2048

  # Network
  vm_ipv4_address = "192.168.1.100/24"
  vm_ipv4_gateway = "192.168.1.1"
  vm_dns_servers  = ["1.1.1.1", "8.8.8.8"]

  # Disk
  vm_disk_size = 50
  vm_disk_ssd  = true
  vm_disk_cache = "writeback"
}
```

### Example with Static IP and Additional Disk

```hcl
module "ci_vm_advanced" {
  source = "./vm_ci_qcow2"

  image_url       = "https://cloud.debian.org/images/cloud/bookworm/daily/20240101-1234/debian-12-genericcloud-amd64-daily-20240101-1234.qcow2"
  image_file_name = "debian-12-ci.qcow2"
  checksum        = "abc123def456..."
  node_name       = "pve-node1"

  user_config_content   = file("${path.module}/user-data.yaml")
  vendor_config_content = file("${path.module}/vendor-data.yaml")

  vm_name        = "ci-runner-02"
  vm_description = "Advanced CI Runner with storage"
  vm_tags        = ["ci", "runner", "storage"]

  # Resources
  vm_cores            = 8
  vm_memory_dedicated = 8192
  vm_memory_floating  = 4096

  # Network
  vm_ipv4_address = "192.168.1.101/24"
  vm_ipv4_gateway = "192.168.1.1"

  # Additional disks
  additional_disks = [
    {
      datastore_id = "local"
      size         = 100
      interface    = "scsi"
      ssd          = true
    },
    {
      datastore_id = "local"
      size         = 200
      interface    = "scsi"
      ssd          = false
    }
  ]

  # Enable protection
  vm_protection = true
}
```

### Example with Cloud-Init Interpolation

```hcl
locals {
  user_data = <<-EOT
    #cloud-config
    package_update: true
    packages:
      - git
      - curl
      - docker.io
    runcmd:
      - systemctl enable docker
      - systemctl start docker
      - useradd -m -s /bin/bash gitlab-runner
  EOT

  vendor_data = <<-EOT
    #cloud-config
    hostname: ci-runner-03
  EOT
}

module "ci_vm_custom" {
  source = "./vm_ci_qcow2"

  image_url       = "https://cloud.debian.org/images/cloud/bookworm/daily/20240101-1234/debian-12-genericcloud-amd64-daily-20240101-1234.qcow2"
  image_file_name = "debian-12-ci.qcow2"
  checksum        = "abc123def456..."
  node_name       = "pve-node1"

  user_config_content   = local.user_data
  vendor_config_content = local.vendor_data

  vm_name = "ci-runner-03"
  vm_tags = ["ci", "docker"]

  vm_ipv4_address = "dhcp"
}
```

### Example with PCIe Device Passthrough

```hcl
module "ci_vm_gpu" {
  source = "./vm_ci_qcow2"

  image_url       = "https://cloud.debian.org/images/cloud/bookworm/daily/20240101-1234/debian-12-genericcloud-amd64-daily-20240101-1234.qcow2"
  image_file_name = "debian-12-ci.qcow2"
  checksum        = "abc123def456..."
  node_name       = "pve-node1"

  user_config_content   = file("${path.module}/user-data.yaml")
  vendor_config_content = file("${path.module}/vendor-data.yaml")

  vm_name        = "ci-runner-gpu"
  vm_description = "CI Runner with GPU Passthrough"
  vm_tags        = ["ci", "gpu", "compute"]

  # Resources for GPU workloads
  vm_cores            = 16
  vm_memory_dedicated = 16384
  vm_memory_floating  = 8192

  # Create PCIe hardware mapping for GPU at cluster level
  pcie_hardware_mappings = [
    {
      name    = "nvidia_gpu"
      comment = "NVIDIA GPU for CI workloads"
      map = [
        {
          node  = "pve-node1"
          path  = "0000:01:00.0"  # GPU path on pve-node1
          id    = "10de:2204"      # NVIDIA L40S
          iommu_group = 37
          subsystem_id = "10de:1447
        }
      ]
    }
  ]

  # Use the mapping in VM
  pcie_devices = [
    {
      device  = "hostpci0"
      mapping = "nvidia_gpu"  # Reference the mapping created above
      pcie    = true
      xvga    = true
    }
  ]
}
```

### Example with Multiple PCIe Devices Using Hardware Mappings

```hcl
module "ci_vm_multi_pcie" {
  source = "./vm_ci_qcow2"

  image_url       = "https://cloud.debian.org/images/cloud/bookworm/daily/20240101-1234/debian-12-genericcloud-amd64-daily-20240101-1234.qcow2"
  image_file_name = "debian-12-ci.qcow2"
  checksum        = "abc123def456..."
  node_name       = "pve-node1"

  user_config_content   = file("${path.module}/user-data.yaml")
  vendor_config_content = file("${path.module}/vendor-data.yaml")

  vm_name = "ci-runner-multi-pcie"
  vm_tags = ["ci", "pcie", "passthrough"]

  # Create multiple hardware mappings
  pcie_hardware_mappings = [
    {
      name    = "amd_gpu"
      comment = "AMD Radeon GPU"
      map = [
        {
          node  = "pve-node1"
          path  = "0000:02:00.0"
          id    = "1002:6863"  # AMD GPU
          iommu_group = 38
        }
      ]
    },
    {
      name    = "intel_nic"
      comment = "Intel Network Interface"
      map = [
        {
          node  = "pve-node1"
          path  = "0000:03:00.0"
          id    = "8086:1521"  # Intel X550
          iommu_group = 39
        }
      ]
    }
  ]

  # Attach mapped devices to VM
  pcie_devices = [
    {
      device  = "hostpci0"
      mapping = "amd_gpu"
      pcie    = true
      xvga    = true
    },
    {
      device  = "hostpci1"
      mapping = "intel_nic"
      pcie    = true
      rombar  = false
    }
  ]
}
```

## PCIe Hardware Mappings

The `pcie_hardware_mappings` variable enables creation of cluster-level PCIe hardware mappings using `proxmox_virtual_environment_hardware_mapping_pci`. These mappings define physical devices and can be referenced by multiple VMs.

> **⚠️ IOMMU Note**: While IOMMU support is recommended for isolation and security, Proxmox supports PCIe passthrough even without IOMMU enabled. See [Finding Device Information](#finding-device-information) section for commands to check IOMMU availability and configuration without it.

### Mapping Structure

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | string | Yes | Mapping name (used to reference in `pcie_devices`) |
| `comment` | string | No | Description of the mapping |
| `mediated_devices` | bool | No | Enable mediated devices support (default: false) |
| `map` | list(object) | Yes | List of physical devices in the mapping |

### Device Map Structure

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `node` | string | Yes | Proxmox node name where device is located |
| `path` | string | Yes | PCI path (e.g., "0000:01:00.0") |
| `id` | string | Yes | Device ID in format `vendor:device` (e.g., "10de:21c4") |
| `comment` | string | No | Device-specific comment |
| `iommu_group` | number | No | IOMMU group number (see [Finding Device Information](#finding-device-information)) |
| `subsystem_id` | string | No | Subsystem ID (e.g., "19da:5527") |

**Optional fields:** `iommu_group` and `subsystem_id` are optional. You can omit them if IOMMU is not available on your system.

### Finding Device Information

To discover PCI devices and their properties on your Proxmox node, SSH into the node and use these commands:

#### 1. List all PCI devices
```bash
lspci -nn | grep -E "VGA|3D|NVIDIA|AMD|Intel"
```
Example output:
```
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation TU116 [GeForce GTX 1660 SUPER] [10de:21c4] (rev a1)
```

#### 2. Get device path and IOMMU group
```bash
realpath /sys/bus/pci/devices/0000:01:00.0/iommu_group/ | grep -oP '\d+$'
```
This returns the IOMMU group number (e.g., `15`)

#### 3. Find all devices in the IOMMU group
```bash
ls /sys/kernel/iommu_groups/15/devices/
```
Shows all devices that must be passed through together (e.g., VGA, Audio, Serial Bus, USB)

#### 4. Get device ID (vendor:device)
```bash
lspci -s 01:00.0 -nn | grep -oP '\[10de:[0-9a-f]+\]'
```
Returns device ID in format like `[10de:21c4]`

#### 5. Get subsystem ID (vendor:device)
```bash
subsystem_vendor=$(cat /sys/bus/pci/devices/0000:01:00.0/subsystem_vendor)
subsystem_device=$(cat /sys/bus/pci/devices/0000:01:00.0/subsystem_device)
echo "${subsystem_vendor#0x}:${subsystem_device#0x}"
```
Returns subsystem ID like `19da:5527`

#### 6. Check IOMMU status
```bash
cat /proc/cmdline | grep iommu
dmesg | grep -i "IOMMU\|iommu enabled"
```

**Understanding IOMMU:**
- If `/proc/cmdline` shows `intel_iommu=on` or `amd_iommu=on` → IOMMU is configured
- If `/sys/kernel/iommu_groups/` has numbered directories → IOMMU groups are available
- If neither exists → IOMMU is not available (you can still use direct device ID)

#### Quick reference script

Save this as `get_pci_info.sh` and run `bash get_pci_info.sh 01:00.0`:

```bash
#!/bin/bash
DEVICE=$1

echo "=== Device Information for $DEVICE ==="
echo

echo "1. Device Name:"
lspci -s "$DEVICE" -nn
echo

echo "2. Device ID:"
lspci -s "$DEVICE" -nn | grep -oP '\[[0-9a-f]+:[0-9a-f]+\]' | tail -1 | tr -d '[]'
echo

echo "3. IOMMU Group:"
iommu_group=$(realpath /sys/bus/pci/devices/0000:$DEVICE/iommu_group/ 2>/dev/null | grep -oP '\d+$')
if [ -z "$iommu_group" ]; then
  echo "Not available (IOMMU not enabled)"
else
  echo "$iommu_group"
fi
echo

if [ ! -z "$iommu_group" ]; then
  echo "4. Devices in IOMMU Group $iommu_group:"
  ls /sys/kernel/iommu_groups/$iommu_group/devices/ | sed 's/^/  /'
  echo
fi

echo "5. Subsystem ID:"
subsystem_vendor=$(cat /sys/bus/pci/devices/0000:$DEVICE/subsystem_vendor 2>/dev/null)
subsystem_device=$(cat /sys/bus/pci/devices/0000:$DEVICE/subsystem_device 2>/dev/null)
if [ ! -z "$subsystem_vendor" ] && [ ! -z "$subsystem_device" ]; then
  echo "${subsystem_vendor#0x}:${subsystem_device#0x}"
else
  echo "Not available"
fi
```

#### Example: NVIDIA GeForce GTX 1660 SUPER

```bash
root@bigpc:~# lspci -s 01:00.0 -nn
0000:01:00.0 VGA compatible controller [0300]: NVIDIA Corporation TU116 [GeForce GTX 1660 SUPER] [10de:21c4]

root@bigpc:~# realpath /sys/bus/pci/devices/0000:01:00.0/iommu_group/ | grep -oP '\d+$'
15

root@bigpc:~# ls /sys/kernel/iommu_groups/15/devices/
0000:01:00.0  0000:01:00.1  0000:01:00.2  0000:01:00.3

root@bigpc:~# cat /sys/bus/pci/devices/0000:01:00.0/subsystem_vendor
0x19da
root@bigpc:~# cat /sys/bus/pci/devices/0000:01:00.0/subsystem_device
0x5527
```

Results in Terraform configuration:
```hcl
pcie_hardware_mappings = [
  {
    name    = "nvidia_gtx1660"
    comment = "NVIDIA GeForce GTX 1660 SUPER"
    map = [
      {
        node         = "bigpc"
        path         = "0000:01:00.0"
        id           = "10de:21c4"
        iommu_group  = 15
        subsystem_id = "19da:5527"
      }
    ]
  }
]
```

## PCIe Device Configuration

The `pcie_devices` variable attaches created mappings (or direct device IDs) to the VM.

### Device Attachment Structure

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `device` | string | Yes | Device slot name (hostpci0-hostpci15) |
| `mapping` | string | No | Reference to a mapping created in `pcie_hardware_mappings` |
| `id` | string | No | Direct PCI device ID (e.g., "8086:5916") - use if no mapping |
| `pcie` | bool | No | Use PCIe instead of PCI (default: true) |
| `rombar` | bool | No | Make firmware ROM visible to VM (default: true) |
| `xvga` | bool | No | Mark device as primary GPU (default: false) |

**Note**: Use either `mapping` (preferred for cluster portability) or `id` (for direct device access), not both.

## Variable Validation

The module includes validations:

- **`vm_bios`**: Must be `seabios` or `ovmf`
- **`vm_ipv4_address`**: Must be `dhcp` or a valid CIDR notation (e.g., `192.168.1.10/24`)

## Provider Information

```terraform
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.87.0"
    }
  }
}
```

Provider configuration should be in your main Terraform file:

```hcl
provider "proxmox" {
  endpoint = "https://your-proxmox-host:8006"
  api_token = var.proxmox_api_token
  insecure = true  # Only for testing with self-signed certificates
}
```

## Notes

- ISO image is downloaded and stored in Proxmox on first run
- Cloud-init must be installed in the image (should be present by default in cloud-init images)
- For `ovmf` BIOS, an EFI partition is automatically created
- Passthrough disks are mapped sequentially (scsi1, scsi2, etc.)
- Proxmox agent is required for IP address discovery
- **PCIe Device Passthrough**:
  - Use `pcie_hardware_mappings` to create cluster-level device mappings (recommended for multi-node clusters)
  - Alternatively, use direct device IDs in `pcie_devices` if mappings don't exist
  - PCIe passthrough requires `vm_type = "q35"` machine type
  - At most 16 PCIe devices can be mapped (hostpci0 to hostpci15)
  - Set `xvga = true` on only one device if using multiple GPUs (marks as primary)
  - Device mappings are automatically created before VM deployment when `pcie_hardware_mappings` is specified
  - Mappings at cluster level can be reused by multiple VMs
  - Removing a mapping from Terraform won't delete it from Proxmox (to prevent accidental device locks)
