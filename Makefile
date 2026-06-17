APP_NAME = SpeakRate
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app

build:
	swift build -c release

bundle: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Sources/SpeakRate/Info.plist $(APP_BUNDLE)/Contents/
	cp Sources/SpeakRate/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/
	codesign --force --sign - $(APP_BUNDLE)

VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")
RELEASE_ZIP = $(APP_NAME)-$(VERSION)-arm64.zip

release: bundle
	rm -f $(RELEASE_ZIP)
	zip -r $(RELEASE_ZIP) $(APP_BUNDLE)
	@echo ""
	@echo "✅ Release ready: $(RELEASE_ZIP)"

icon:
	mkdir -p tools/png
	swift tools/make_icon.swift tools/png
	rm -rf tools/SpeakRate.iconset && mkdir tools/SpeakRate.iconset
	cp tools/png/icon_16.png   tools/SpeakRate.iconset/icon_16x16.png
	cp tools/png/icon_32.png   tools/SpeakRate.iconset/icon_16x16@2x.png
	cp tools/png/icon_32.png   tools/SpeakRate.iconset/icon_32x32.png
	cp tools/png/icon_64.png   tools/SpeakRate.iconset/icon_32x32@2x.png
	cp tools/png/icon_128.png  tools/SpeakRate.iconset/icon_128x128.png
	cp tools/png/icon_256.png  tools/SpeakRate.iconset/icon_128x128@2x.png
	cp tools/png/icon_256.png  tools/SpeakRate.iconset/icon_256x256.png
	cp tools/png/icon_512.png  tools/SpeakRate.iconset/icon_256x256@2x.png
	cp tools/png/icon_512.png  tools/SpeakRate.iconset/icon_512x512.png
	cp tools/png/icon_1024.png tools/SpeakRate.iconset/icon_512x512@2x.png
	iconutil -c icns tools/SpeakRate.iconset -o Sources/SpeakRate/AppIcon.icns

install: bundle
	cp -r $(APP_BUNDLE) /Applications/
	open /Applications/$(APP_BUNDLE)

run: bundle
	open $(APP_BUNDLE)

clean:
	rm -rf .build $(APP_BUNDLE) *.zip
