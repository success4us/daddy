.PHONY: help all formatcheck format test vet lint qa coverage

GOFMT_FILES?=$$(find . -name '*.go' | grep -v vendor)
FILES_WITHOUT_PROPER_FORMAT?=$$(gofmt -l -s ${GOFMT_FILES})

# Tools
BIN_DIR = $(GOPATH)/bin
GOLINT = $(BIN_DIR)/golint
$(GOLINT):
	go get -u golang.org/x/lint/golint

help:
	@echo ""
	@echo "The following commands are available:"
	@echo ""
	@echo "    make qa          : Ensure project quality"
	@echo "    make format      : Format the source code"
	@echo "    make formatcheck : Check if the source code has been formatted"
	@echo "    make vet         : Look for suspicious constructs"
	@echo "    make test        : Run tests"
	@echo "    make lint        : Check for style errors"
	@echo ""

all: help

formatcheck:
	@echo "Checking file format..."
	@if [ ! -z "$(FILES_WITHOUT_PROPER_FORMAT)" ]; then \
		echo "The following files have formatting errors:"; \
		echo "$(FILES_WITHOUT_PROPER_FORMAT)"; \
		exit 1; \
	else \
		echo "OK"; \
	fi;

format:
	@echo "Formatting files..."
	@gofmt -w -s $(GOFMT_FILES)
	@echo "OK"

test:
	@echo "Testing..."
	@go test -i ./... || exit 1
	@go test -timeout=60s -parallel=4 ./...

vet:
	@echo "Looking for suspicious constructs..."
	@go vet ./...
	@echo "OK"

lint: $(GOLINT)
	@echo "Checking for style errors..."
	golint ./...
	@test -z "$$(golint ./...)"
	@echo "OK"

COVERAGE_DIR     = coverage
COVERAGE_MODE    = atomic
COVERAGE_PROFILE = $(COVERAGE_DIR)/profile.out
COVERAGE_HTML    = $(COVERAGE_DIR)/index.html
coverage:
	@echo "Running coverage..."
	mkdir -p $(COVERAGE_DIR)
	go test \
		-covermode=$(COVERAGE_MODE) \
		-coverprofile="$(COVERAGE_PROFILE)" ./...
	go tool cover -html=$(COVERAGE_PROFILE) -o $(COVERAGE_HTML)

qa: formatcheck vet lint test
qa-ci: formatcheck vet lint coverage
