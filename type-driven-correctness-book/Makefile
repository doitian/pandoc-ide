REPO_RAW_URL := https://raw.githubusercontent.com/microsoft/RustTraining/main/type-driven-correctness-book/src
SRC_DIR := src

CHAPTERS := \
	ch00-introduction.md \
	ch01-the-philosophy-why-types-beat-tests.md \
	ch02-typed-command-interfaces-request-determi.md \
	ch03-single-use-types-cryptographic-guarantee.md \
	ch04-capability-tokens-zero-cost-proof-of-aut.md \
	ch05-protocol-state-machines-type-state-for-r.md \
	ch06-dimensional-analysis-making-the-compiler.md \
	ch07-validated-boundaries-parse-dont-validate.md \
	ch08-capability-mixins-compile-time-hardware-.md \
	ch09-phantom-types-for-resource-tracking.md \
	ch10-putting-it-all-together-a-complete-diagn.md \
	ch11-fourteen-tricks-from-the-trenches.md \
	ch12-exercises.md \
	ch13-reference-card.md \
	ch14-testing-type-level-guarantees.md \
	ch15-const-fn-compile-time-correctness-proofs.md \
	ch16-send-sync-compile-time-concurrency-proofs.md \
	ch17-redfish-applied-walkthrough.md \
	ch18-redfish-server-walkthrough.md

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
