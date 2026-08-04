.PHONY: build test lint format check package clean

VERSION ?= 0.0.0-dev

build:
	swift build

test:
	swift test

lint:
	xcrun swift-format lint --strict --recursive Sources Tests Package.swift

format:
	xcrun swift-format format --in-place --recursive Sources Tests Package.swift

check: lint build test

package:
	./scripts/package-release.sh "$(VERSION)"

clean:
	swift package clean
	rm -rf dist
