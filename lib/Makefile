.PHONY: build test clean

XCODE_DEV_ROOT := $(shell xcode-select -p)
XCODE_PROJECT := ../topaz.xcodeproj
XCODE_OPTIONS := -skipPackagePluginValidation -skipMacroValidation

SWIFT_TARGET := App

IOS_VERSION := 18
IOS_ARCH := arm64
IOS_TRIPLE := $(IOS_ARCH)-apple-ios$(IOS_VERSION).0
IOS_SDK_PATH := $(XCODE_DEV_ROOT)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk

# Builds just the SPM modules in isolation (way faster than xcodebuild)
build:
	swift build --sdk "$(IOS_SDK_PATH)" --triple "$(IOS_TRIPLE)" --scratch-path "$(SCRATCH_PATH)" --target $(SWIFT_TARGET)

clean:
	rm -rf .build build


# Unfortunately `swift test` is not working for simulator target, seems to be a bug :(
# So below we do a bunch of nonsense to run the SPM tests.

SCRATCH_PATH := .build/$(IOS_TRIPLE)
SIM_ID_CACHE := $(SCRATCH_PATH)/simid.txt

$(SCRATCH_PATH):
	mkdir -p $@

# Extracts the id string of the first simulator found for this os+version and saves it to SIM_ID_CACHE file
$(SIM_ID_CACHE): $(SCRATCH_PATH)
	xcodebuild \
		-project $(XCODE_PROJECT) \
		-scheme $(SWIFT_TARGET) \
		-sdk iphoneos \
		-destination 'platform=iOS Simulator' \
		-showdestinations 2>&1 \
		| grep 'platform:iOS Simulator, id:.*, OS:$(IOS_VERSION).*, name:iPhone 16 Pro' \
		| head -1 \
		| sed -e s'/^.*id:\([^,]*\).*,.*$$/\1/' > $@

# Extracts the test targets by grokking the folders from within Tests directory:
TEST_FOLDERS := $(wildcard Tests/*)
TEST_MODULES := $(patsubst Tests/%,%,$(TEST_FOLDERS))

test: $(TEST_MODULES)

# Instead of `swift test`, run each target. Still waaaaay faster than the main app test
%Tests: $(SIM_ID_CACHE)
	xcodebuild \
		-project $(XCODE_PROJECT) \
		-sdk iphoneos \
		-scheme $* \
		-destination "platform=iOS Simulator,id=$(shell cat $(SIM_ID_CACHE))" \
		build \
		$(XCODE_OPTIONS) \
		CODE_SIGNING_ALLOWED='NO'
	xcodebuild \
		-project $(XCODE_PROJECT) \
		-sdk iphoneos \
		-scheme $@ \
		-destination "platform=iOS Simulator,id=$(shell cat $(SIM_ID_CACHE))" \
		test \
		$(XCODE_OPTIONS) \
		CODE_SIGNING_ALLOWED='NO'
