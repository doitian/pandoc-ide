REPO_RAW_URL := https://raw.githubusercontent.com/microsoft/RustTraining/main/async-book/src
SRC_DIR := src

CHAPTERS := \
	ch00-introduction.md \
	ch01-why-async-is-different-in-rust.md \
	ch02-the-future-trait.md \
	ch03-how-poll-works.md \
	ch04-pin-and-unpin.md \
	ch05-the-state-machine-reveal.md \
	ch06-building-futures-by-hand.md \
	ch07-executors-and-runtimes.md \
	ch08-tokio-deep-dive.md \
	ch09-when-tokio-isnt-the-right-fit.md \
	ch10-async-traits.md \
	ch11-streams-and-asynciterator.md \
	ch12-common-pitfalls.md \
	ch13-production-patterns.md \
	ch14-exercises.md \
	ch15-summary-and-reference-card.md \
	ch16-capstone-project.md

SRC_FILES := $(addprefix $(SRC_DIR)/,$(CHAPTERS))

.PHONY: all download build clean

all: download build

download: $(SRC_FILES)

CURL_OPTS := -fsSL
ifdef GITHUB_TOKEN
CURL_OPTS += -H "Authorization: token $(GITHUB_TOKEN)"
endif

$(SRC_DIR)/%.md:
	@mkdir -p $(SRC_DIR)
	curl $(CURL_OPTS) "$(REPO_RAW_URL)/$*.md" -o "$@"

build: download
	../bin/pandoc -d pandoc

clean:
	rm -rf $(SRC_DIR) *.pdf mermaid-*.png
