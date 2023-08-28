# Base ##################################################################
FROM ubuntu:jammy AS ubuntu-builder-base

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -q --no-allow-insecure-repositories update \
  && DEBIAN_FRONTEND=noninteractive \
     apt-get install --assume-yes --no-install-recommends \
       ca-certificates=* \
       curl=* \
       unzip=* \
       p7zip=* \
       git=* \
  && rm -rf /var/lib/apt/lists/*

# Builder ###############################################################
FROM ubuntu-builder-base as ubuntu-builder

RUN curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/NerdFontsSymbolsOnly.zip \
  && unzip -d NerdFontsSymbolsOnly NerdFontsSymbolsOnly.zip \
  && mv NerdFontsSymbolsOnly /fonts/symbols-nerd-font

RUN git clone --depth=1 --quiet \
  https://github.com/doitian/dotfiles-public \
  /dotfiles-public

# Output ################################################################
FROM pandoc/latex:latest-ubuntu as pandoc-ide

# Reinstall any system packages required for runtime.
RUN apt-get -q --no-allow-insecure-repositories update \
  && DEBIAN_FRONTEND=noninteractive \
     apt-get install --assume-yes --no-install-recommends \
       fonts-lato \
       fonts-roboto-slab \
       fonts-cascadia-code \
       fonts-noto \
       fonts-noto-cjk \
  && rm -rf /var/lib/apt/lists/*

RUN tlmgr install \
      koma-script adjustbox tcolorbox collectbox ucs environ \
      trimspaces titling enumitem rsfs xecjk fvextra svg transparent \
      xpatch changepage ifoddpage lineno \
  && TERM=dumb luaotfload-tool --update

COPY --from=ubuntu-builder \
  /fonts \
  /.local/share/fonts

COPY --from=ubuntu-builder \
  /dotfiles-public/pandoc \
  /.pandoc

RUN ln -s /.pandoc /root/.pandoc \
  && ln -s /.local /root/.local \
  && fc-cache -f
