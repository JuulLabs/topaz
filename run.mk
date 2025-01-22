.PHONY: run rebuild

APP_FOLDER_NAME := $(XCODE_TARGET).app
BUILT_APP_PATH := $(DERIVED_DATA_PATH)/Build/Products/$(XCODE_CONFIG)-iphoneos/$(APP_FOLDER_NAME)
WRAPPER_PATH := $(DERIVED_DATA_PATH)/Run/$(APP_FOLDER_NAME)

run: rebuild $(WRAPPER_PATH)
	open $(WRAPPER_PATH)

# Structure required to execute iPad app on macOS:
# topaz.app/
# topaz.app/WrappedBundle -> Wrapper/topaz.app (symlink)
# topaz.app/Wrapper/topaz.app/<actual app files go here>
#
$(WRAPPER_PATH): $(BUILT_APP_PATH)
	-rm -rf $(WRAPPER_PATH)
	mkdir -p $(WRAPPER_PATH)/Wrapper
	ln -s Wrapper/$(APP_FOLDER_NAME) $(WRAPPER_PATH)/WrappedBundle
	ditto $(BUILT_APP_PATH) $(WRAPPER_PATH)/Wrapper/$(APP_FOLDER_NAME)

rebuild:
	-pkill $(XCODE_TARGET)
	$(MAKE) PLATFORM=MACOS build
