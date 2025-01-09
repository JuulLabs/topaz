.PHONY: build test clean

XCODE_DEV_ROOT := $(shell xcode-select -p)

TARGET ?= App

IOS_VERSION := 18
IOS_ARCH := arm64
IOS_TRIPLE := $(IOS_ARCH)-apple-ios$(IOS_VERSION).0
IOS_SDK_PATH := $(XCODE_DEV_ROOT)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk

# Builds just the SPM modules in isolation (way faster than xcodebuild)
build:
	swift build --sdk "$(IOS_SDK_PATH)" --triple "$(IOS_TRIPLE)" --scratch-path "$(SCRATCH_PATH)" --target $(TARGET)

clean:
	rm -rf .build build

# Unfortunately `swift test` is not working for simulator target, seems to be a bug :(
# Instead run `make test` in the project root to run the tests via xcodebuild.
test:
	@echo 'Run `make test` in the project root instead'
