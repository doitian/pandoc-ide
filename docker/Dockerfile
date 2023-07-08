# Base ##################################################################
FROM ubuntu:jammy AS ubuntu-builder-base

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -q --no-allow-insecure-repositories update \
  && DEBIAN_FRONTEND=noninteractive \
     apt-get install --assume-yes --no-install-recommends \
       ca-certificates=* \
       curl=* \
       git \
  && rm -rf /var/lib/apt/lists/*

# Builder ###############################################################
FROM ubuntu-builder-base as ubuntu-builder

RUN git clone --depth=1 --quiet \
      https://github.com/lxgw/LxgwBright.git \
      /LxgwBright \
  && git clone --depth=1 --quiet \
       https://github.com/lxgw/LxgwWenKai.git \
       /LxgwWenKai \
  && mkdir /fonts \
  && mv /LxgwBright/LXGWBrightGB /fonts/LxgwBrightGB \
  && mv /LxgwWenKai/fonts/TTF /fonts/LxgwWenKai

RUN git clone --depth=1 --quiet \
  https://github.com/doitian/dotfiles-public \
  /dotfiles-public

# Output ################################################################
FROM pandoc/latex:latest-ubuntu as pandoc-ide

COPY --from=ubuntu-builder \
  /fonts \
  /.local/share/fonts

COPY --from=ubuntu-builder \
  /dotfiles-public/pandoc \
  /.pandoc

RUN ln -s /.pandoc /root/.pandoc \
  && ln -s /.local /root/.local

# Reinstall any system packages required for runtime.
RUN apt-get -q --no-allow-insecure-repositories update \
  && DEBIAN_FRONTEND=noninteractive \
     apt-get install --assume-yes --no-install-recommends \
       fonts-ibm-plex \
       fonts-lato \
       fonts-jetbrains-mono \
       fonts-noto-cjk \
  && rm -rf /var/lib/apt/lists/*

RUN tlmgr install \
      koma-script adjustbox tcolorbox collectbox ucs environ \
      trimspaces titling enumitem rsfs xecjk fvextra svg transparent \
      xpatch changepage ifoddpage \
  && TERM=dumb luaotfload-tool --update