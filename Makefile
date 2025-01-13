include build.mk publish.mk run.mk

.PHONY: all lint lint-fix clean js js-debug js-clean

# Default target
all: build

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
