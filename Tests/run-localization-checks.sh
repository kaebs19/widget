#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
localization_check_dir=$(mktemp -d)
trap 'rm -rf "$localization_check_dir"' EXIT
xcrun swiftc -parse-as-library Shared/Localization/AppLanguage.swift Shared/Localization/PrayerNotificationText.swift Tests/LocalizationChecks.swift -o "$localization_check_dir/checks"
"$localization_check_dir/checks" "${1:?Pass the path to a built app or extension bundle}"
