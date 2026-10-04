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

RUN curl -fsSLO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/NerdFontsSymbolsOnly.zip \
  && unzip -d NerdFontsSymbolsOnly NerdFontsSymbolsOnly.zip \
  && curl -fsSLO https://github.com/googlefonts/atkinson-hyperlegible-next/raw/main/fonts/otf/AtkinsonHyperlegibleNext-Regular.otf \
  && curl -fsSLO https://github.com/googlefonts/atkinson-hyperlegible-next/raw/main/fonts/otf/AtkinsonHyperlegibleNext-Italic.otf \
  && curl -fsSLO https://github.com/googlefonts/atkinson-hyperlegible-next/raw/main/fonts/otf/AtkinsonHyperlegibleNext-Bold.otf \
  && curl -fsSLO https://github.com/googlefonts/atkinson-hyperlegible-next/raw/main/fonts/otf/AtkinsonHyperlegibleNext-BoldItalic.otf \
  && mkdir -p /fonts /fonts/atkinson-hyperlegible-next \
  && mv NerdFontsSymbolsOnly /fonts/symbols-nerd-font \
  && mv AtkinsonHyperlegibleNext-*.otf /fonts/atkinson-hyperlegible-next

RUN git clone --filter=tree:0 --quiet https://github.com/doitian/dotfiles-public /dotfiles-public \
  && git -C /dotfiles-public checkout 95912872603d1e474112870777cacd6898a48d0b

# Output ################################################################
FROM pandoc/latex:latest-ubuntu as pandoc-ide

# Reinstall any system packages required for runtime.
RUN apt-get -q --no-allow-insecure-repositories update \
  && DEBIAN_FRONTEND=noninteractive \
     apt-get install --assume-yes --no-install-recommends \
       fonts-lato \
       fonts-inter \
       fonts-roboto-slab \
       fonts-jetbrains-mono \
       fonts-noto-cjk \
       fonts-noto-color-emoji \
  && rm -rf /var/lib/apt/lists/*

RUN tlmgr update --self \
  && tlmgr install \
      koma-script adjustbox tcolorbox collectbox ucs environ \
      trimspaces titling enumitem rsfs xecjk fvextra svg transparent \
      xpatch changepage ifoddpage lineno haranoaji luatexja \
  && TERM=dumb luaotfload-tool --update

COPY --from=ubuntu-builder \
  /fonts \
  /usr/local/share/fonts

COPY --from=ubuntu-builder \
  /dotfiles-public/pandoc \
  /usr/local/share/pandoc

RUN fc-cache -f

