REPO_RAW_URL := https://raw.githubusercontent.com/microsoft/RustTraining/main/rust-patterns-book/src
SRC_DIR := src

CHAPTERS := \
	ch00-introduction.md \
	ch01-generics-the-full-picture.md \
	ch02-traits-in-depth.md \
	ch03-the-newtype-and-type-state-patterns.md \
	ch04-phantomdata-types-that-carry-no-data.md \
	ch05-channels-and-message-passing.md \
	ch06-concurrency-vs-parallelism-vs-threads.md \
	ch07-closures-and-higher-order-functions.md \
	ch08-functional-vs-imperative-when-elegance-wins.md \
	ch09-smart-pointers-and-interior-mutability.md \
	ch10-error-handling-patterns.md \
	ch11-serialization-zero-copy-and-binary-data.md \
	ch12-unsafe-rust-controlled-danger.md \
	ch13-macros-code-that-writes-code.md \
	ch14-testing-and-benchmarking-patterns.md \
	ch15-crate-architecture-and-api-design.md \
	ch16-asyncawait-essentials.md \
	ch17-exercises.md \
	ch18-summary-and-reference-card.md \
	ch19-capstone-project.md

SRC_FILES := $(addprefix $(SRC_DIR)/,$(CHAPTERS))

.PHONY: all download mermaid build clean

all: download build

download: $(SRC_FILES)

CURL_OPTS := -fsSL
ifdef GITHUB_TOKEN
CURL_OPTS += -H "Authorization: token $(GITHUB_TOKEN)"
endif

$(SRC_DIR)/%.md:
	@mkdir -p $(SRC_DIR)
	curl $(CURL_OPTS) "$(REPO_RAW_URL)/$*.md" -o "$@"

mermaid: download
	../bin/mermaid-preprocess $(SRC_FILES)

build: mermaid
	../bin/pandoc -d pandoc

clean:
	rm -rf $(SRC_DIR) *.pdf
