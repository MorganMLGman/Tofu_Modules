#!/usr/bin/env bash
# Scaffolds a workspace into a temp dir and checks that the result formats, validates and rejects bad input.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp templates/docker_workspace/workspace.env.example "$tmp/.docker-workspace.env"

scripts/new_docker_workspace.sh "$tmp" demo 8080 >/dev/null
test -z "$(grep -rl '@[A-Z_]*@' "$tmp/demo_docker" || true)" || { echo "unreplaced placeholder left in output" >&2; exit 1; }
grep -q 'skierki/demo_docker/terraform.tfstate' "$tmp/demo_docker/_backend.tf"
grep -q 'lxc_demo' "$tmp/demo_docker/_locals.tf"
grep -q '\.ip}:8080' "$tmp/demo_docker/_outputs.tf"

tofu fmt -check "$tmp/demo_docker"
tofu -chdir="$tmp/demo_docker" init -backend=false -input=false >/dev/null
tofu -chdir="$tmp/demo_docker" validate

scripts/new_docker_workspace.sh "$tmp" demo 2>/dev/null && { echo "must refuse an existing workspace" >&2; exit 1; }
scripts/new_docker_workspace.sh "$tmp" "Bad-Name" 2>/dev/null && { echo "must refuse a bad name" >&2; exit 1; }
scripts/new_docker_workspace.sh "$tmp" other abc 2>/dev/null && { echo "must refuse a non-numeric port" >&2; exit 1; }
echo "scaffold ok"
