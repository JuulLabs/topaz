.PHONY: build test boot-simulator

XCODE_PROJECT := topaz.xcodeproj
XCODE_TARGET ?= topaz
XCODE_SCHEME ?= topaz
XCODE_COMMAND ?= build
XCODE_CONFIG ?= Debug
XCODE_OPTIONS += -skipPackagePluginValidation -skipMacroValidation

ifeq ($(XCODE_CONFIG),Debug)
ifneq ($(PLATFORM),MACOS)
	override XCODE_EXTRA_PARAMS += CODE_SIGNING_ALLOWED='NO'
endif
endif

DERIVED_DATA_ROOT := .derivedData
DERIVED_DATA_PATH := $(DERIVED_DATA_ROOT)/$(XCODE_CONFIG)

IOS_SIM_UUID := $(shell ./scripts/find_optimal_sim_uuid.sh)
PLATFORM_IOS := platform=iOS Simulator,id=$(IOS_SIM_UUID)
PLATFORM_MACOS := platform=macOS,arch=arm64,variant=Designed for iPad
PLATFORM_GENERIC := generic/platform=iOS

PLATFORM ?= IOS

XCODE_DESTINATION := $(PLATFORM_$(PLATFORM))

PLATFORM_ID := $(shell echo "$(XCODE_DESTINATION)" | grep 'id=' | sed -E "s/.+,id=(.+)/\1/")

XCODEBUILD_FLAGS = \
	-configuration $(XCODE_CONFIG) \
	-derivedDataPath $(DERIVED_DATA_PATH) \
	-destination '$(XCODE_DESTINATION)' \
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

# Hack to find hanging test
# test: $(TEST_MODULES)
test: XCODE_SCHEME := NavigationTests
test: boot-simulator
	xcodebuild $(XCODEBUILD_FLAGS) test $(XCODE_EXTRA_PARAMS) \
		-only-testing 'NavigationTests/NavigationRequestTests/initFromAction_withNilURL_isNil()()'
	xcodebuild $(XCODEBUILD_FLAGS) test-without-building $(XCODE_EXTRA_PARAMS) \
		-only-testing 'NavigationTests/NavigationRequestTests/initFromAction_withNoTargetFrameAndSourceIsMainFrame_navigatesToNewWindow()()'
	xcodebuild $(XCODEBUILD_FLAGS) test-without-building $(XCODE_EXTRA_PARAMS) \
		-only-testing 'NavigationTests/NavigationRequestTests/initFromAction_withNoTargetFrameAndSourceIsNotMainFrame_isNil()()'
	xcodebuild $(XCODEBUILD_FLAGS) test-without-building $(XCODE_EXTRA_PARAMS) \
		-only-testing 'NavigationTests/NavigationRequestTests/initFromAction_withRequestAndTargetOriginMismatch_navigatesToCrossOrigin()()'
	xcodebuild $(XCODEBUILD_FLAGS) test-without-building $(XCODE_EXTRA_PARAMS) \
		-only-testing 'NavigationTests/NavigationRequestTests/initFromAction_withRequestAndTargetOriginMatch_navigatesToSameOrigin()()'

# failing?
#	xcodebuild $(XCODEBUILD_FLAGS) test $(XCODE_EXTRA_PARAMS) \
#		-only-testing 'NavigationTests/NavigationRequestTests/initFromAction_withValidRequest_takesUrlAndActionTypeFromAction()()'

%Tests: XCODE_SCHEME = $@
%Tests: XCODE_COMMAND := test
%Tests: boot-simulator
	$(XCODEBUILD)

boot-simulator:
	@if [ ! -z "$(IOS_SIM_UUID)" ]; then \
		xcrun simctl list devices available; \
		echo "Booting simulator for iOS with id: $(PLATFORM_ID)"; \
		xcrun simctl list | grep $(PLATFORM_ID) | grep -q Booted || xcrun simctl boot $(PLATFORM_ID); \
		open -a Simulator --args -CurrentDeviceUDID $(PLATFORM_ID); \
	elif [ "$(PLATFORM)" = "IOS" ]; then \
		xcrun simctl list devices available; \
		xcodebuild -showdestinations -scheme "$(XCODE_SCHEME)" -project $(XCODE_PROJECT); \
		echo "ERROR: Compatible iOS simulator not found"; \
		exit 1; \
	fi
