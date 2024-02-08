###############################################################################
###                                  Build                                  ###
###############################################################################

build-help:
	@echo "build subcommands"
	@echo ""
	@echo "Usage:"
	@echo "  make build-[command]"
	@echo ""
	@echo "Available Commands:"
	@echo "  all                              Build all targets"
	@echo "  check-version                    Check Go version"
	@echo "  dev-build                        Build development version"
	@echo "  dev-install                      Install development build"

build-check-version:
	@echo "Go version: $(GO_MAJOR_VERSION).$(GO_MINOR_VERSION)"
	@if [ $(GO_MAJOR_VERSION) -gt $(GO_MINIMUM_MAJOR_VERSION) ]; then \
		echo "Go version is sufficient"; \
		exit 0; \
	elif [ $(GO_MAJOR_VERSION) -lt $(GO_MINIMUM_MAJOR_VERSION) ]; then \
		echo '$(GO_VERSION_ERR_MSG)'; \
		exit 1; \
	elif [ $(GO_MINOR_VERSION) -lt $(GO_MINIMUM_MINOR_VERSION) ]; then \
		echo '$(GO_VERSION_ERR_MSG)'; \
		exit 1; \
	fi

build-all: build-check-version go.sum
	mkdir -p $(BUILDDIR)/
	GOWORK=off go build -mod=readonly $(BUILD_FLAGS) -o $(BUILDDIR)/ ./...

# disables optimization, inlining and symbol removal
GC_FLAGS := -gcflags="all=-N -l"
REMOVE_STRING := -w -s
DEBUG_BUILD_FLAGS:= $(subst $(REMOVE_STRING),,$(BUILD_FLAGS))
DEBUG_LDFLAGS = $(subst $(REMOVE_STRING),,$(ldflags))

build-dev-install: go.sum
	GOWORK=off go install $(DEBUG_BUILD_FLAGS) $(GC_FLAGS) $(GO_MODULE)/cmd/solizd

build-dev-build:
	mkdir -p $(BUILDDIR)/
	GOWORK=off go build $(GC_FLAGS) -mod=readonly -ldflags '$(DEBUG_LDFLAGS)' -trimpath -o $(BUILDDIR) ./...;