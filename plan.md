# Docker Image Update Plan

Update the `pandoc-ide` Docker image to support `lualatex-zh-base` defaults and Mermaid diagram rendering.

## Changes to `docker/Dockerfile`

### 1. Add `fonts-noto-color-emoji` system package

The `lualatex-zh-base` defaults chain includes `lualatex-font-zh.tex`, which configures Noto Color Emoji as a font fallback. Add the package to the existing `apt-get install` block:

```diff
        fonts-noto-cjk \
+       fonts-noto-color-emoji \
   && rm -rf /var/lib/apt/lists/*
```

### 2. Add `luatexja` TeX package

The `lualatex-zh-base` defaults use `lualatex` as the PDF engine and include `lualatex-font-zh.tex`, which requires `luatexja-fontspec`. Add `luatexja` to the existing `tlmgr install` command:

```diff
-      xpatch changepage ifoddpage lineno haranoaji \
+      xpatch changepage ifoddpage lineno haranoaji luatexja \
```

### 3. Install Node.js and mermaid-cli

The `type-driven-correctness-book` project uses a Lua filter (`filters/mermaid.lua`) that shells out to `mmdc` (mermaid-cli) to render Mermaid diagrams as PNG images. Add a new `RUN` layer after the font-cache step:

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

## Why

The CI for the `type-driven-correctness-book` project fails with `"Error producing PDF"` because:
- The project switched from `xelatex-reprt` to `lualatex-zh-base` defaults, which requires the `luatexja` TeX package and the Noto Color Emoji font — neither is present in the current Docker image.
- The Mermaid Lua filter needs `mmdc` at runtime to convert `mermaid` code blocks into images.

## After merging

Push this change to `master` (or trigger the Docker workflow manually) so `docker-workflow.yml` rebuilds and pushes the updated `ghcr.io/doitian/pandoc-ide:latest` image. Once the new image is available, re-run the failing Pandoc CI workflow.
