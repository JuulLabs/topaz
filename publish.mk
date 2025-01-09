.PHONY: ipa validate-ipa upload-ipa

APP_BUILD ?= 1
APP_VERSION ?= 1.0.0

XCODE_CONFIG ?= Release

include build.mk

# Some notes about publishing using CLI:
# https://tarikdahic.com/posts/build-ios-apps-from-the-command-line-using-xcodebuild/

API_ISSUER_ID ?= 69a6de8c-2ff1-47e3-e053-5b8c7c11a4d1
API_KEY_ID ?= 26CY8KZRBV

ARTIFACTS_ROOT := artifacts
IPA_ARTIFACT := $(ARTIFACTS_ROOT)/$(XCODE_TARGET).ipa
ARCHIVE_ARTIFACT := $(ARTIFACTS_ROOT)/$(XCODE_TARGET).xcarchive
EXPORT_PLIST := Topaz/ExportOptions-$(XCODE_CONFIG).plist
VERSION_FILE := Topaz/version.xcconfig

# Using App Store Connect API credentials enables "automatic code signing".
# The app loader tool requires that the private key be saved to ./private_keys/ and correctly named.
API_KEY_DIR := ./private_keys
API_KEY_FILE := $(API_KEY_DIR)/AuthKey_$(API_KEY_ID).p8

# xcodebuild requires absolute path to the key file:
API_KEY_FILE_ABS = $(shell readlink -f $(API_KEY_FILE))

XCODE_ARCHIVE_OPTIONS = \
	-archivePath $(ARCHIVE_ARTIFACT) \
	-allowProvisioningUpdates \
	-authenticationKeyPath $(API_KEY_FILE_ABS) \
	-authenticationKeyID $(API_KEY_ID) \
	-authenticationKeyIssuerID $(API_ISSUER_ID)

$(API_KEY_FILE):
	@if test -z "$(API_KEY_FILE_ABS)"; then \
		echo "API key file not found: $(API_KEY_FILE)"; \
		exit 1; \
	fi

$(ARCHIVE_ARTIFACT): $(API_KEY_FILE)
	mkdir -p $(ARTIFACTS_ROOT)
	echo 'CURRENT_PROJECT_VERSION = $(APP_BUILD)' > $(VERSION_FILE)
	echo 'MARKETING_VERSION = $(APP_VERSION)' >> $(VERSION_FILE)
	$(MAKE) \
		PLATFORM=GENERIC \
		XCODE_OPTIONS='$(XCODE_ARCHIVE_OPTIONS)' \
		XCODE_COMMAND=archive \
		build

$(IPA_ARTIFACT): $(ARCHIVE_ARTIFACT)
	xcodebuild \
		$(XCODE_ARCHIVE_OPTIONS) \
		-exportPath $(ARTIFACTS_ROOT) \
		-exportOptionsPlist $(EXPORT_PLIST) \
		-exportArchive

ipa: $(IPA_ARTIFACT)

validate-ipa: $(IPA_ARTIFACT)
	xcrun altool --validate-app -f $< -t ios --apiKey $(API_KEY_ID) --apiIssuer $(API_ISSUER_ID)

upload-ipa: $(IPA_ARTIFACT)
	xcrun altool --upload-app -f $< -t ios --apiKey $(API_KEY_ID) --apiIssuer $(API_ISSUER_ID)
