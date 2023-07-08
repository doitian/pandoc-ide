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

RUN curl -LO \
      https://github.com/lxgw/LxgwWenKai/releases/download/v1.300/lxgw-wenkai-v1.300.zip \
  && unzip lxgw-wenkai-v1.300.zip \
  && curl -LO \
       https://github.com/lxgw/LxgwBright/releases/download/v5.300/LXGWBrightGB.7z \
  && 7zr x LXGWBrightGB.7z \
  && curl -LO \
       https://github.com/13rac1/twemoji-color-font/releases/download/v14.0.2/TwitterColorEmoji-SVGinOT-Linux-14.0.2.tar.gz \
  && tar -xzf TwitterColorEmoji-SVGinOT-Linux-14.0.2.tar.gz \
  && mkdir -p /fonts/lxgw-wenkai \
  && mv lxgw-wenkai-v1.300/*.ttf /fonts/lxgw-wenkai/ \
  && mkdir -p /fonts/lxgw-bright-gb \
  && mv LXGWBrightGB/*.otf /fonts/lxgw-bright-gb/ \
  && mkdir -p /fonts/twitter-color-emoji \
  && mv TwitterColorEmoji-SVGinOT-Linux-14.0.2/TwitterColorEmoji-SVGinOT.ttf /fonts/twitter-color-emoji/

RUN git clone --depth=1 --quiet \
  https://github.com/doitian/dotfiles-public \
  /dotfiles-public

# Output ################################################################
FROM pandoc/latex:latest-ubuntu as pandoc-ide

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