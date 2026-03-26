# Docker Image Update Plan

Fix the `pandoc-ide` Docker image so pandoc can find custom defaults files (`lualatex-zh-base`, etc.) and add mermaid-cli for diagram rendering.

## Problem

The base image `pandoc/latex:latest-ubuntu` sets `XDG_DATA_HOME=/usr/local/share`. Pandoc 3.9 uses `$XDG_DATA_HOME/pandoc` as its user data directory, which resolves to `/usr/local/share/pandoc/` (empty). The Dockerfile was copying custom defaults/filters/templates to `/.pandoc/`, which is not in pandoc's search path. This caused:

```
lualatex-zh-base.yaml: withBinaryFile: does not exist (No such file or directory)
```

## Changes to `docker/Dockerfile`

### 1. Copy pandoc data files to the XDG user data directory

Change the COPY destination from `/.pandoc` to `/usr/local/share/pandoc` (where pandoc 3.9 actually looks):

```diff
 COPY --from=ubuntu-builder \
   /dotfiles-public/pandoc \
-  /.pandoc
+  /usr/local/share/pandoc
```

### 2. Remove the now-unnecessary `/root` symlinks

```diff
-RUN ln -s /.pandoc /root/.pandoc \
-  && ln -s /.local /root/.local \
-  && fc-cache -f
+RUN fc-cache -f
```

The symlinks were a workaround for the legacy `$HOME/.pandoc` path. With files now in `$XDG_DATA_HOME/pandoc`, they are no longer needed.

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

## After merging

Rebuild and push the Docker image from `master` so the updated `ghcr.io/doitian/pandoc-ide:latest` is available. Then re-run the Pandoc CI workflow.
