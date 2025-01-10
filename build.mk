.PHONY: build test boot-simulator

XCODE_PROJECT := topaz.xcodeproj
XCODE_TARGET ?= topaz
XCODE_SCHEME ?= topaz
XCODE_COMMAND ?= build
XCODE_CONFIG ?= Debug
XCODE_OPTIONS += -skipPackagePluginValidation -skipMacroValidation

ifeq ($(XCODE_CONFIG),Debug)
	override XCODE_EXTRA_PARAMS += CODE_SIGNING_ALLOWED='NO'
endif

DERIVED_DATA_ROOT := .derivedData
DERIVED_DATA_PATH := $(DERIVED_DATA_ROOT)/$(XCODE_CONFIG)

define udid_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$(NF-3) }')
endef

PLATFORM_IOS := platform="iOS Simulator,id=$(call udid_for,iOS,iPhone \d\+ Pro [^M])"
PLATFORM_MACOS := platform=macOS
PLATFORM_GENERIC := generic/platform=iOS

PLATFORM ?= IOS

XCODE_DESTINATION := $(PLATFORM_$(PLATFORM))

PLATFORM_ID := $(shell echo "$(XCODE_DESTINATION)" | grep 'id=' | sed -E "s/.+,id=(.+)/\1/")

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

%Tests: XCODE_SCHEME = $@
%Tests: XCODE_COMMAND := test
%Tests: boot-simulator
	$(XCODEBUILD)

boot-simulator:
	@if [ ! -z "$(PLATFORM_ID)" ]; then \
		echo "Booting simulator with id: $(PLATFORM_ID)"; \
		xcrun simctl list | grep $(PLATFORM_ID) | grep -q Booted || xcrun simctl boot $(PLATFORM_ID); \
		open -a Simulator --args -CurrentDeviceUDID $(PLATFORM_ID); \
	fi
