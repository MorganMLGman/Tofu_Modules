#!/usr/bin/env bash
# Scaffolds workspaces from a fake consumer repo and checks values are read from it, the output validates,
# and missing input fails loudly.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
mkdir -p "$repo/old_docker"

cat > "$repo/_backend.tf" <<'TF'
terraform {
  backend "s3" {
    profile                     = "my-profile"
    bucket                      = "my-bucket"
    key                         = "home/terraform.tfstate"
    region                      = "eu-test-1"
    skip_credentials_validation = true
    endpoints = {
      s3 = "https://s3.example.test"
    }
  }
}
TF
# Legacy-style workspace: differently named blocks and a flat `local.cf`.
cat > "$repo/old_docker/_secrets.tf" <<'TF'
data "scaleway_secret_version" "secret_my_app" {
  secret_id = "11111111-1111-1111-1111-111111111111"
  revision  = "latest"
}

data "scaleway_secret_version" "secret_cloudflare" {
  secret_id = "22222222-2222-2222-2222-222222222222"
  revision  = "latest"
}
TF
cat > "$repo/old_docker/_providers.tf" <<'TF'
provider "cloudflare" {
  api_token = sensitive(local.cf.my_token_key)
}
TF
echo 'locals { cf_domain = "example.test" }' > "$repo/old_docker/_locals.tf"

run() { python3 -I scripts/new_docker_workspace.py "$@"; }

run "$repo" demo 8080 >/dev/null
out="$repo/demo_docker"
test -z "$(grep -rl '@[A-Z_]*@' "$out" || true)" || { echo "unreplaced placeholder left in output" >&2; exit 1; }
grep -q 'key *= "home/demo_docker/terraform.tfstate"' "$out/_backend.tf"
grep -q 'bucket *= "my-bucket"' "$out/_backend.tf"
grep -q 'profile *= "my-profile"' "$out/_providers.tf"
grep -q 's3 *= "https://s3.example.test"' "$out/_providers.tf"
grep -q '11111111-1111-1111-1111-111111111111' "$out/_secrets.tf"
grep -q '22222222-2222-2222-2222-222222222222' "$out/_secrets.tf"
grep -q 'local.secrets.cloudflare.my_token_key' "$out/_providers.tf"
grep -q 'cf_domain *= "example.test"' "$out/_locals.tf"
grep -q 'lxc_demo' "$out/_locals.tf"
grep -q '\.ip}:8080' "$out/_outputs.tf"

tofu fmt -check "$out"
tofu -chdir="$out" init -backend=false -input=false >/dev/null
tofu -chdir="$out" validate

run "$repo" demo 2>/dev/null && { echo "must refuse an existing workspace" >&2; exit 1; }
run "$repo" "Bad-Name" 2>/dev/null && { echo "must refuse a bad name" >&2; exit 1; }
run "$repo" other abc 2>/dev/null && { echo "must refuse a non-numeric port" >&2; exit 1; }

# A repo with nothing to read from must fail and name what is missing; env vars fill the gaps.
empty="$tmp/empty"
mkdir "$empty"
msg=$(run "$empty" x </dev/null 2>&1) && { echo "must fail without a backend" >&2; exit 1; }
grep -q 'not found' <<<"$msg"
STATE_PROFILE=p STATE_BUCKET=b STATE_REGION=r STATE_ENDPOINT=https://e STATE_PREFIX=pre \
  APP_SECRET_ID=a CLOUDFLARE_SECRET_ID=c CF_DOMAIN=d CF_API_TOKEN_KEY=k run "$empty" x </dev/null >/dev/null
grep -q 'key *= "pre/x_docker/terraform.tfstate"' "$empty/x_docker/_backend.tf"

echo "scaffold ok"
