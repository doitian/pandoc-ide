# Docker Image Update Plan

Fix the `pandoc-ide` Docker image so pandoc can find custom defaults files (`lualatex-zh-base`, etc.) when the container runs as a non-root user via `--user`, and add mermaid-cli for diagram rendering.

## Problem

The `bin/pandoc` wrapper runs `docker run --user "$(id -u):$(id -g)" …`, which means the pandoc process runs as a non-root user (e.g., UID 1001 on GitHub Actions). The current Dockerfile stores defaults in `/.pandoc/` and creates a symlink `/root/.pandoc -> /.pandoc`. But `/root/` has mode `700` (only accessible by root), so the non-root user **cannot traverse** `/root/.pandoc` and pandoc fails with:

```
lualatex-zh-base.yaml: withBinaryFile: does not exist (No such file or directory)
```

## Changes to `docker/Dockerfile`

### 1. Set `HOME=/` so the pandoc data directory is accessible to any user

Add before the `COPY` and `RUN` commands in the output stage:

```diff
+ENV HOME /
+
 COPY --from=ubuntu-builder \
   /fonts \
   /.local/share/fonts
```

With `HOME=/`, pandoc resolves `$HOME/.pandoc` → `/.pandoc`, which is world-readable. The legacy user data directory (`$HOME/.pandoc`) is used when the directory exists and is not a symlink to the XDG location, which is exactly our setup.

### 2. Remove the now-unnecessary `/root` symlinks

```diff
-RUN ln -s /.pandoc /root/.pandoc \
-  && ln -s /.local /root/.local \
-  && fc-cache -f
+RUN fc-cache -f
```

The `/root/.pandoc` and `/root/.local` symlinks were a workaround for `HOME=/root`. With `HOME=/`, they are no longer needed.

### 3. Install Node.js and mermaid-cli

The `type-driven-correctness-book` project uses a Lua filter (`filters/mermaid.lua`) that shells out to `mmdc` to render Mermaid diagrams. Add a new `RUN` layer:

```dockerfile
# Install Node.js and mermaid-cli for rendering Mermaid diagrams in Lua filters
RUN apt-get -q --no-allow-insecure-repositories update \
  && DEBIAN_FRONTEND=noninteractive \
     apt-get install --assume-yes --no-install-recommends \
       nodejs=* \
       npm=* \
       chromium-browser=* \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g @mermaid-js/mermaid-cli \
  && npm cache clean --force
```

## Full diff from current master

```diff
 FROM pandoc/latex:latest-ubuntu as pandoc-ide

+ENV HOME /
+
 # Reinstall any system packages required for runtime.
 ...existing apt-get and tlmgr install blocks (already correct on master)...

 COPY --from=ubuntu-builder /fonts /.local/share/fonts
 COPY --from=ubuntu-builder /dotfiles-public/pandoc /.pandoc

-RUN ln -s /.pandoc /root/.pandoc \
-  && ln -s /.local /root/.local \
-  && fc-cache -f
+RUN fc-cache -f
+
+# Install Node.js and mermaid-cli for rendering Mermaid diagrams in Lua filters
+RUN apt-get -q --no-allow-insecure-repositories update \
+  && DEBIAN_FRONTEND=noninteractive \
+     apt-get install --assume-yes --no-install-recommends \
+       nodejs=* \
+       npm=* \
+       chromium-browser=* \
+  && rm -rf /var/lib/apt/lists/* \
+  && npm install -g @mermaid-js/mermaid-cli \
+  && npm cache clean --force
```

## After merging

Rebuild and push the Docker image from `master` so the updated `ghcr.io/doitian/pandoc-ide:latest` is available. Then re-run the Pandoc CI workflow.
