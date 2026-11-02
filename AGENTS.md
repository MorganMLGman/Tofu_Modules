# AGENTS.md

Reusable OpenTofu modules (Proxmox, Docker, Cloudflare, MikroTik). Library only: no state, no providers configured, no `apply` here. Consumers live in other repos and pin modules by git ref.

## Layout

Directories are grouped by the provider a module drives: `proxmox/`, `docker/`, `cloudflare/`, `mikrotik/`. Each module has `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tf` and a `README.md`. The module index is in [README.md](README.md). `templates/docker_workspace/` and `scripts/new_docker_workspace.py` scaffold the per-host docker workspaces of consumer repos; change the template, not generated copies.

## Commands

```bash
scripts/check.sh                 # fmt -check, validate every module, tofu test where tests/ exists, scaffold test (also run by CI)
tofu fmt -recursive <dir>        # fix formatting
tofu -chdir=proxmox/lxc test     # mock-provider tests for the LXC module
```

Never run `tofu apply` or `tofu plan` against real infrastructure from this repo. `check.sh` leaves `.terraform/` and lock files behind; they are gitignored.

## Rules

- **Modules reference each other by relative path** (`../../cloudflare/...`), never by a git URL, so a tag always carries a consistent set.
- **A breaking change** (renamed or removed input/output, changed resource address) needs a `moved {}` block where state can be migrated, and an entry in [MIGRATION.md](MIGRATION.md).
- **Module versions** are tagged per module (`proxmox-lxc/v1.0.0`), not one tag for the whole repo.
- **MAC addresses** in `proxmox/lxc` are derived from `md5("<hostname>/<interface>")`. Changing that formula changes the MAC of every container that does not pin one.
- **Docker images** are pinned by registry digest (`name@sha256:...`) and referenced through `image_id`. A bare tag with `pull_triggers` does not re-pull and leaves containers stale.
- `required_version` in modules is a lower bound (`>= 1.11.2`), never `~>`.
- Every input and output has a `description`. Validate input at the module boundary with `validation` blocks.
- Logic that can be tested without a provider (names, MACs, merged lists, preconditions) gets a `tofu test` run with `mock_provider`. A test written for a fix must fail when the fix is reverted.

## Style

- English everywhere: code, comments, descriptions, docs, commit messages.
- Comments only for a non-obvious why or a trap; do not restate the code or the provider docs.
- Commits follow Conventional Commits, one line, no body.
- Keep files formatted with `tofu fmt`; do not mix formatting-only changes into a functional diff.
