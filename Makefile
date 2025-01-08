.PHONY: build test lint lint-fix clean boot-simulator

XCODE_PROJECT := topaz.xcodeproj
XCODE_TARGET ?= topaz
XCODE_SCHEME ?= topaz
XCODE_COMMAND ?= build
XCODE_CONFIG ?= Debug
XCODE_EXTRA_PARAMS ?= CODE_SIGNING_ALLOWED='NO'
XCODE_OPTIONS := -skipPackagePluginValidation -skipMacroValidation

DERIVED_DATA_PATH = .derivedData/$(CONFIG)

PLATFORM_IOS = iOS Simulator,id=$(call udid_for,iOS,iPhone \d\+ Pro [^M])
PLATFORM_MACOS := macOS

PLATFORM ?= IOS

XCODE_DESTINATION = platform="$(PLATFORM_$(PLATFORM))"

PLATFORM_ID = $(shell echo "$(XCODE_DESTINATION)" | sed -E "s/.+,id=(.+)/\1/")

XCODEBUILD_FLAGS = \
	-configuration $(XCODE_CONFIG) \
	-derivedDataPath $(DERIVED_DATA_PATH) \
	-destination $(XCODE_DESTINATION) \
	-scheme "$(XCODE_SCHEME)" \
	-project $(XCODE_PROJECT) \
	$(XCODE_OPTIONS)

XCODEBUILD_COMMAND = xcodebuild $(XCODEBUILD_FLAGS) $(XCODE_COMMAND) $(XCODE_EXTRA_PARAMS)

ifneq ($(strip $(shell which xcbeautify)),)
	XCODEBUILD = set -o pipefail && $(XCODEBUILD_COMMAND) | xcbeautify
else
	XCODEBUILD = $(XCODEBUILD_COMMAND)
endif

# Extracts the test targets by grokking the folders from within Tests directory:
TEST_FOLDERS := $(wildcard lib/Tests/*)
TEST_MODULES := $(patsubst lib/Tests/%,%,$(TEST_FOLDERS))

build: XCODE_COMMAND := build
build: boot-simulator
	$(XCODEBUILD)

test: $(TEST_MODULES)

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
	rm -rf .build build $(DERIVED_DATA_PATH)

%Tests: XCODE_SCHEME = $@
%Tests: XCODE_COMMAND := test
%Tests: boot-simulator
	$(XCODEBUILD)

boot-simulator:
	@test "$(PLATFORM_ID)" != "" \
		&& xcrun simctl list | grep $(PLATFORM_ID) | grep -q Booted || xcrun simctl boot $(PLATFORM_ID) \
		&& open -a Simulator --args -CurrentDeviceUDID $(PLATFORM_ID) \
		|| exit 0

define udid_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$(NF-3) }')
endef
