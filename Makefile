.PHONY: all help lint lint-fix clean js js-debug js-clean

# Default target - must be first
all: help

include build.mk publish.mk run.mk

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  help       Display this help message"
	@echo "  build      Build the project"
	@echo "  test       Build and run all unit tests"
	@echo "  run        Launch the 'Designed for iPad' variant as a macOS app"
	@echo "  ipa        Build the app store IPA artifact"
	@echo "  js         Build the JavaScript polyfill artifacts"
	@echo "  js-debug   Build the JavaScript polyfill artifacts without minification"
	@echo "  js-clean   Clean the JavaScript build"
	@echo "  lint       Lint the project"
	@echo "  lint-fix   Fix linting issues"
	@echo "  clean      Clean the project"
	@echo ""
	@echo "Test targets:"
	@echo $(TEST_MODULES) | tr ' ' '\n' | sed -e 's/^/  /'

js:
	$(MAKE) -C lib/Javascript build

js-debug:
	$(MAKE) -C lib/Javascript debug

js-clean:
	$(MAKE) -C lib/Javascript clean

lint:
	swiftlint lint --strict

lint-fix:
	swiftlint lint --fix

## TODO: deprecate swiftlint in favor of swift-format
lint-official:
	swift format lint --strict -r .
 
lint-fix-official:
	swift format -i -r .

clean:
	-rm -rf .build build $(DERIVED_DATA_ROOT) $(ARTIFACTS_ROOT)
