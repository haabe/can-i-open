APP_NAME = Can I Open
BUNDLE_ID = com.canIOpen.app
EXECUTABLE = CanIOpen
BUILD_DIR = .build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
VERSION = 0.1.0

.PHONY: build run clean

build:
	swift build -c release
	@echo "Assembling app bundle..."
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp "$(BUILD_DIR)/release/$(EXECUTABLE)" "$(APP_BUNDLE)/Contents/MacOS/$(EXECUTABLE)"
	@/usr/libexec/PlistBuddy -c "Clear dict" "$(APP_BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	@/usr/libexec/PlistBuddy \
		-c "Add :CFBundleIdentifier string $(BUNDLE_ID)" \
		-c "Add :CFBundleName string $(APP_NAME)" \
		-c "Add :CFBundleDisplayName string $(APP_NAME)" \
		-c "Add :CFBundleExecutable string $(EXECUTABLE)" \
		-c "Add :CFBundleVersion string $(VERSION)" \
		-c "Add :CFBundleShortVersionString string $(VERSION)" \
		-c "Add :CFBundlePackageType string APPL" \
		-c "Add :LSMinimumSystemVersion string 13.0" \
		-c "Add :NSHighResolutionCapable bool true" \
		-c "Add :CFBundleInfoDictionaryVersion string 6.0" \
		"$(APP_BUNDLE)/Contents/Info.plist"
	@echo "Built: $(APP_BUNDLE)"

run: build
	@open "$(APP_BUNDLE)"

debug:
	swift build
	@echo "Assembling debug app bundle..."
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp "$(BUILD_DIR)/debug/$(EXECUTABLE)" "$(APP_BUNDLE)/Contents/MacOS/$(EXECUTABLE)"
	@/usr/libexec/PlistBuddy -c "Clear dict" "$(APP_BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	@/usr/libexec/PlistBuddy \
		-c "Add :CFBundleIdentifier string $(BUNDLE_ID)" \
		-c "Add :CFBundleName string $(APP_NAME)" \
		-c "Add :CFBundleDisplayName string $(APP_NAME)" \
		-c "Add :CFBundleExecutable string $(EXECUTABLE)" \
		-c "Add :CFBundleVersion string $(VERSION)" \
		-c "Add :CFBundleShortVersionString string $(VERSION)" \
		-c "Add :CFBundlePackageType string APPL" \
		-c "Add :LSMinimumSystemVersion string 13.0" \
		-c "Add :NSHighResolutionCapable bool true" \
		-c "Add :CFBundleInfoDictionaryVersion string 6.0" \
		"$(APP_BUNDLE)/Contents/Info.plist"
	@codesign --force --sign - --identifier "$(BUNDLE_ID)" "$(APP_BUNDLE)"
	@open "$(APP_BUNDLE)"

clean:
	swift package clean
	rm -rf "$(APP_BUNDLE)"
