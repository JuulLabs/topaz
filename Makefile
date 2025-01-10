include publish.mk

.PHONY: all lint lint-fix clean js js-debug js-clean run

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

# Structure required to execute iPad app on macOS:
# topaz.app/
# topaz.app/WrappedBundle -> Wrapper/topaz.app
# topaz.app/Wrapper/topaz.app/<actual app files go here>
#
$(DERIVED_DATA_PATH)/Run/topaz.app: $(DERIVED_DATA_PATH)/Build/Products/Debug-iphoneos/topaz.app
	mkdir -p $(DERIVED_DATA_PATH)/Run/topaz.app/Wrapper
	ln -s Wrapper/topaz.app $(DERIVED_DATA_PATH)/Run/topaz.app/WrappedBundle
	ditto $(DERIVED_DATA_PATH)/Build/Products/Debug-iphoneos/topaz.app $(DERIVED_DATA_PATH)/Run/topaz.app/Wrapper/topaz.app

$(DERIVED_DATA_PATH)/Build/Products/Debug-iphoneos/topaz.app:
	$(MAKE) PLATFORM=MACOS build

run: $(DERIVED_DATA_PATH)/Run/topaz.app
	open $(DERIVED_DATA_PATH)/Run/topaz.app
