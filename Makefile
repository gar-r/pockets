ADDON_NAME := pockets
ADDON_DIR := $(shell find ~ -path '*/_retail_/Wow.exe' -print0 -quit 2>/dev/null | xargs -0 dirname)/Interface/AddOns
ADDON_VERSION := $(shell grep '## Version' pockets.toc | cut -d ' ' -f 3)

install: uninstall
	mkdir -p "$(ADDON_DIR)/$(ADDON_NAME)"
	cp -rf . "$(ADDON_DIR)/$(ADDON_NAME)"

test:
	lua5.1 tests/test_sm.lua
	lua5.1 tests/test_config.lua
	lua5.1 tests/test_tracker.lua
	lua5.1 tests/test_gold.lua

uninstall:
	rm -rf "$(ADDON_DIR)/$(ADDON_NAME)"

release: clean
	mkdir -p dist/$(ADDON_NAME)
	rsync -av --exclude=".*" --exclude="assets/" --exclude="tests/" --exclude="dist" . dist/$(ADDON_NAME)
	cd dist && zip -r $(ADDON_NAME)_v$(ADDON_VERSION).zip $(ADDON_NAME)/*

clean:
	rm -rf dist/*
