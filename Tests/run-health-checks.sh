#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
health_device=${1:-booted}
health_check_dir=$(mktemp -d)
trap 'rm -rf "$health_check_dir"' EXIT
health_sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -parse-as-library \
    -sdk "$health_sdk" -target arm64-apple-ios18.6-simulator \
    Tests/HealthCheckSupport.swift Shared/Models/Health.swift \
    Shared/Models/HealthDisplaySettings.swift Shared/Models/HealthGoals.swift \
    Shared/Models/HealthInsights.swift Shared/Models/WaterTracker.swift Tests/HealthChecks.swift \
    -o "$health_check_dir/checks"
xcrun simctl spawn "$health_device" "$health_check_dir/checks"
