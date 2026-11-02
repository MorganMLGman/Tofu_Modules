#!/usr/bin/env python3
"""Scaffold <repo>/<name>_docker/ from templates/docker_workspace.

Usage: new_docker_workspace.py <consumer-repo-dir> <name> [port]

State backend values come from <repo>/_backend.tf. Secret ids, domain and token key are read from the
repo's existing *_docker workspaces. Anything that cannot be found is asked for, or taken from the
environment (STATE_BUCKET, STATE_PROFILE, STATE_REGION, STATE_ENDPOINT, STATE_PREFIX, APP_SECRET_ID,
CLOUDFLARE_SECRET_ID, CF_DOMAIN, CF_API_TOKEN_KEY).
"""
import os
import re
import sys
from collections import Counter
from pathlib import Path

TEMPLATES = Path(__file__).resolve().parent.parent / "templates" / "docker_workspace"


def read_all(paths):
    return [p.read_text() for p in paths if p.is_file()]


def most_common(values):
    return Counter(values).most_common(1)[0][0] if values else None


def backend_values(repo):
    text = (repo / "_backend.tf").read_text() if (repo / "_backend.tf").is_file() else ""

    def attr(name):
        m = re.search(rf'^\s*{name}\s*=\s*"([^"]+)"', text, re.M)
        return m.group(1) if m else None

    endpoint = re.search(r's3\s*=\s*"([^"]+)"', text)
    key = attr("key")
    return {
        "STATE_PROFILE": attr("profile"),
        "STATE_BUCKET": attr("bucket"),
        "STATE_REGION": attr("region"),
        "STATE_ENDPOINT": endpoint.group(1) if endpoint else None,
        "STATE_PREFIX": key.rsplit("/", 1)[0] if key and "/" in key else None,
    }


def workspace_values(repo):
    workspaces = sorted(p for p in repo.glob("*_docker") if p.is_dir())
    secrets = read_all(w / "_secrets.tf" for w in workspaces)
    blocks = [
        (name, uid)
        for text in secrets
        for name, uid in re.findall(
            r'data "scaleway_secret_version" "([^"]+)" \{\s*secret_id\s*=\s*"([0-9a-f-]{36})"', text
        )
    ]
    providers = read_all(w / "_providers.tf" for w in workspaces)
    token = [
        m
        for text in providers
        for m in re.findall(r"api_token\s*=\s*(?:sensitive\()?local\.[\w.]*?\.(\w+)\)?\s*$", text, re.M)
    ]
    domains = [m for w in workspaces for f in w.glob("*.tf") for m in re.findall(r'cf_domain\s*=\s*"([^"]+)"', f.read_text())]
    return {
        "CLOUDFLARE_SECRET_ID": most_common([u for n, u in blocks if "cloudflare" in n]),
        "APP_SECRET_ID": most_common([u for n, u in blocks if "cloudflare" not in n]),
        "CF_API_TOKEN_KEY": most_common(token),
        "CF_DOMAIN": most_common(domains),
    }


def resolve(repo):
    values = {**workspace_values(repo), **backend_values(repo)}
    for key in list(values):
        if os.environ.get(key):
            values[key] = os.environ[key]
    missing = [k for k, v in values.items() if not v]
    for key in missing:
        if sys.stdin.isatty():
            values[key] = input(f"{key} (not found in {repo}): ").strip()
        if not values[key]:
            sys.exit(f"{key} not found in {repo}; set it in the environment, e.g. {key}=...")
    values["SCW_REGION"] = os.environ.get("SCW_REGION") or values["STATE_REGION"]
    return values


def main():
    if len(sys.argv) not in (3, 4):
        sys.exit(__doc__)
    repo, name = Path(sys.argv[1]), sys.argv[2]
    port = sys.argv[3] if len(sys.argv) == 4 else ""
    if not re.fullmatch(r"[a-z][a-z0-9_]*", name):
        sys.exit(f"name must match [a-z][a-z0-9_]*: {name}")
    if port and not port.isdigit():
        sys.exit(f"port must be a number: {port}")
    target = repo / f"{name}_docker"
    if target.exists():
        sys.exit(f"{target} already exists")

    values = resolve(repo)
    values["NAME"] = name
    values["PORT_SUFFIX"] = f":{port}" if port else ""

    target.mkdir()
    for tpl in sorted(TEMPLATES.glob("*.tf.tpl")):
        text = tpl.read_text()
        for key, value in values.items():
            text = text.replace(f"@{key}@", value)
        (target / tpl.name.removesuffix(".tpl")).write_text(text)

    print(f"created {target}")
    print(f"next: add 'output \"lxc_{name}\" {{ value = module.lxc_{name}.connection }}' to the LXC layer, then tofu init in {target}")


main()
