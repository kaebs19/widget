#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
feature_check_dir=$(mktemp -d)
trap 'rm -rf "$feature_check_dir"' EXIT
xcrun swiftc -parse-as-library \
    Tests/FeatureCheckSupport.swift \
    Shared/Models/Subscriptions.swift Shared/Models/Occasion.swift \
    Shared/Models/QuranGoal.swift Shared/Models/Azkar.swift \
    Tests/FeatureChecks.swift -o "$feature_check_dir/checks"
"$feature_check_dir/checks"
