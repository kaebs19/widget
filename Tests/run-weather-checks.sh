#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
weather_test_dir=$(mktemp -d)
trap 'rm -rf "$weather_test_dir"' EXIT
weather_sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -parse-as-library -sdk "$weather_sdk" -target arm64-apple-ios18.6-simulator \
    Shared/Localization/AppLanguage.swift Shared/Models/Weather.swift Tests/WeatherChecks.swift -o "$weather_test_dir/checks"
xcrun simctl spawn "${1:-booted}" "$weather_test_dir/checks"
