#!/usr/bin/env bash
# Local gate: formatting, validate every module, run the module tests.
set -euo pipefail
cd "$(dirname "$0")/.."

tofu fmt -check -recursive proxmox/lxc proxmox/vm_ci_qcow2 docker cloudflare mikrotik

for dir in $(find proxmox/lxc proxmox/vm_ci_qcow2 docker cloudflare mikrotik -name terraform.tf -printf '%h\n' | sort); do
  echo "== validate $dir"
  tofu -chdir="$dir" init -backend=false -input=false -lockfile=readonly >/dev/null 2>&1 \
    || tofu -chdir="$dir" init -backend=false -input=false >/dev/null
  tofu -chdir="$dir" validate
  if [ -d "$dir/tests" ]; then tofu -chdir="$dir" test; fi
done
