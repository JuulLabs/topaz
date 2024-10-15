.PHONY: build test lint lint-fix clean sim-build sim-test _xcode_build

XCODE_PROJECT := topaz.xcodeproj
XCODE_TARGET := topaz

IOS_VERSION := 18
IOS_ARCH := arm64
IOS_TRIPLE := $(IOS_ARCH)-apple-ios$(IOS_VERSION).0

XCODE_DESTINATION ?= generic/platform=iOS
XCODE_COMMAND ?= build

build:
	$(MAKE) XCODE_COMMAND=build _xcode_build

test:
	$(MAKE) XCODE_COMMAND=test _xcode_build

sim-build: $(SIM_ID_CACHE)
	$(MAKE) XCODE_COMMAND=build XCODE_DESTINATION=$(shell cat $<) _xcode_build

sim-test: $(SIM_ID_CACHE)
	$(MAKE) XCODE_COMMAND=test XCODE_DESTINATION=$(shell cat $<) _xcode_build

clean:
	rm -rf .build build

_xcode_build:
	xcodebuild \
		-project $(XCODE_PROJECT) \
		-target $(XCODE_TARGET) \
		-sdk iphoneos \
		-destination $(XCODE_DESTINATION) \
		$(XCODE_COMMAND) \
		CODE_SIGNING_ALLOWED='NO'

SCRATCH_PATH := .build/$(IOS_TRIPLE)
SIM_ID_CACHE := $(SCRATCH_PATH)/simid.txt

$(SCRATCH_PATH):
	mkdir -p $@

# Extracts the id string of the first simulator found for this os+version and saves it to SIM_ID_CACHE file
$(SIM_ID_CACHE): $(SCRATCH_PATH)
	xcodebuild \
		-project $(XCODE_PROJECT) \
		-target $(XCODE_TARGET) \
		-sdk iphoneos \
		-destination 'platform=iOS Simulator' \
		-showdestinations 2>&1 \
		| grep 'platform:iOS Simulator, id:.*, OS:$(IOS_VERSION).*, name:iPhone 16 Pro' \
		| head -1 \
		| sed -e s'/^.*id:\([^,]*\).*,.*$$/\1/' > $@

