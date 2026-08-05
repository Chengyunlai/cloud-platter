.PHONY: adapter build test lint format check package design-prototype clean

VERSION ?= 0.0.0-dev

adapter:
	./scripts/build-mediaremote-adapter.sh

build:
	swift build

test:
	swift test

lint:
	xcrun swift-format lint --strict --configuration .swift-format --recursive Sources Tests Package.swift

format:
	xcrun swift-format format --in-place --configuration .swift-format --recursive Sources Tests Package.swift

check: lint build test

package:
	./scripts/package-release.sh "$(VERSION)"

design-prototype:
	python3 -m http.server 4173 --directory Prototypes/FullscreenDesktop

clean:
	swift package clean
	rm -rf dist
