# docker/image

A Docker image pinned by registry digest. Replaces the `data "docker_registry_image"` + `resource "docker_image"` pair repeated for every container.

```hcl
module "postgres_image" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//docker/image?ref=<tag>"
  name   = "postgres:17"
}

resource "docker_container" "db" {
  image = module.postgres_image.image_id
  # ...
}
```

- `image_id` changes whenever the digest does, so containers that use it are recreated. This is the output to use.
- `name` is the digest-pinned reference. Use it only where a container already references the image by name; switching an existing container from `name` to `image_id` replaces it.
- Adopting existing images: `moved { from = docker_image.x  to = module.x_image.docker_image.this }`. Only images already named `<ref>@sha256:...` move without a replacement; an image pinned by tag with `pull_triggers` gets a new name and is replaced, together with its containers.
