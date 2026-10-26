#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
# Pass an already booted simulator UUID when several devices are running.
typography_device=${1:-booted}
typography_check_dir=$(mktemp -d)
trap 'rm -rf "$typography_check_dir"' EXIT
typography_sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -parse-as-library \
    -sdk "$typography_sdk" -target arm64-apple-ios18.6-simulator \
    Tests/TypographyCheckSupport.swift Shared/DesignSystem/AppFonts.swift \
    Shared/Customization/WidgetStyle.swift Tests/TypographyChecks.swift \
    -o "$typography_check_dir/checks"
xcrun simctl spawn "$typography_device" "$typography_check_dir/checks" "$PWD/Shared/Resources/Fonts"
