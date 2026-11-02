#!/usr/bin/env bash
# Scaffold <repo>/<name>_docker/ (backend, providers, secrets, locals, outputs) from templates/docker_workspace.
# Usage: new_docker_workspace.sh <consumer-repo-dir> <name> [port]
set -euo pipefail

repo=${1:?usage: $0 <consumer-repo-dir> <name> [port]}
name=${2:?usage: $0 <consumer-repo-dir> <name> [port]}
port=${3:-}

[[ $name =~ ^[a-z][a-z0-9_]*$ ]] || { echo "name must match ^[a-z][a-z0-9_]*$: $name" >&2; exit 1; }
[[ -z $port || $port =~ ^[0-9]+$ ]] || { echo "port must be a number: $port" >&2; exit 1; }
config="$repo/.docker-workspace.env"
[ -f "$config" ] || { echo "missing $config (start from templates/docker_workspace/workspace.env.example)" >&2; exit 1; }

target="$repo/${name}_docker"
[ ! -e "$target" ] || { echo "$target already exists" >&2; exit 1; }

set -a
# shellcheck disable=SC1090
source "$config"
set +a

for key in STATE_PROFILE STATE_BUCKET STATE_REGION STATE_ENDPOINT STATE_PREFIX SCW_REGION APP_SECRET_ID CLOUDFLARE_SECRET_ID CF_DOMAIN CF_API_TOKEN_KEY; do
  [ -n "${!key:-}" ] || { echo "$key is not set in $config" >&2; exit 1; }
done

templates="$(dirname "$0")/../templates/docker_workspace"
mkdir "$target"
for tpl in "$templates"/*.tf.tpl; do
  out="$target/$(basename "${tpl%.tpl}")"
  sed -e "s|@NAME@|$name|g" \
      -e "s|@PORT_SUFFIX@|${port:+:$port}|g" \
      -e "s|@STATE_PROFILE@|$STATE_PROFILE|g" \
      -e "s|@STATE_BUCKET@|$STATE_BUCKET|g" \
      -e "s|@STATE_REGION@|$STATE_REGION|g" \
      -e "s|@STATE_ENDPOINT@|$STATE_ENDPOINT|g" \
      -e "s|@STATE_PREFIX@|$STATE_PREFIX|g" \
      -e "s|@SCW_REGION@|$SCW_REGION|g" \
      -e "s|@APP_SECRET_ID@|$APP_SECRET_ID|g" \
      -e "s|@CLOUDFLARE_SECRET_ID@|$CLOUDFLARE_SECRET_ID|g" \
      -e "s|@CF_DOMAIN@|$CF_DOMAIN|g" \
      -e "s|@CF_API_TOKEN_KEY@|$CF_API_TOKEN_KEY|g" \
      "$tpl" > "$out"
done

echo "created $target"
echo "next: add 'output \"lxc_$name\" { value = module.lxc_$name.connection }' to the LXC layer, then tofu init in $target"
