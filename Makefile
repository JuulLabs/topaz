.PHONY: all help lint lint-fix clean js js-debug js-clean js-check

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
	@echo "  js-check   Verify the committed JavaScript artifacts match a fresh build"
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

JS_GENERATED_DIR := lib/Sources/WebView/Resources/Generated

js-check:
	$(MAKE) js-clean
	$(MAKE) js-debug
	@if [ -n "$$(git status --porcelain -- $(JS_GENERATED_DIR))" ]; then \
		git status --short -- $(JS_GENERATED_DIR); \
		git --no-pager diff --stat -- $(JS_GENERATED_DIR); \
		echo "ERROR: Generated JavaScript is out of date. Run 'make js-clean js-debug' and commit the result."; \
		exit 1; \
	fi

lint:
	swiftlint lint --strict

lint-fix:
	swiftlint lint --fix

## TODO: deprecate swiftlint in favor of swift-format
lint-official:
	swift format lint --strict -r .
 
lint-fix-official:
	swift format -i -r .

log-watch:
	log stream --source --level debug --style compact --predicate 'process=="topaz" AND sender=="topaz.debug.dylib" AND subsystem!="WebView"'

clean:
	-rm -rf .build build $(DERIVED_DATA_ROOT) $(ARTIFACTS_ROOT)
