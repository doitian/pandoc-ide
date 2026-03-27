# Agents

## Cursor Cloud specific instructions

This repo is a Docker-based document conversion toolkit ("Pandoc as Service"). There is no traditional application server, no package manager dependencies, and no test suite. The only system dependency is **Docker**.

### Running the product

The `ghcr.io/doitian/pandoc-ide:latest` image is the core artifact. It is pre-built and available from GHCR; pulling it is much faster than building locally.

- **Convert a manuscript to PDF:** `cd manuscript && sudo docker run --rm --volume "$(pwd):/data" ghcr.io/doitian/pandoc-ide -d pandoc`
- **Use the `bin/pandoc` wrapper:** `cd manuscript && sudo /workspace/bin/pandoc -d pandoc` (equivalent to the above)
- **Interactive shell in the container:** `sudo /workspace/bin/sh`

### Docker-in-Docker caveats

The Cloud Agent VM runs inside a container. Docker requires:

1. `fuse-overlayfs` storage driver (configured in `/etc/docker/daemon.json`)
2. `iptables-legacy` (set via `update-alternatives`)
3. `sudo dockerd` must be running before any `docker` commands
4. All `docker` commands must use `sudo` (the `ubuntu` user is not in the docker group in fresh sessions)

### Building the image locally

`sudo docker build -t ghcr.io/doitian/pandoc-ide:latest /workspace/docker/` — note that the `tlmgr install` step depends on external TeX Live mirrors (FTP) which may be unreliable. Prefer pulling the pre-built image unless you are modifying the Dockerfile.

### Lint / test / build

- **No linter** is configured in this repository.
- **No automated test suite** exists.
- **Build** = building the Docker image (see above) or converting documents.
- The CI workflows (`.github/workflows/`) handle image publishing and document conversion on push. See the README for details.
