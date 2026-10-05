#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/quietspot-community-siri.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -module-cache-path "$test_dir/module-cache" \
    QuietSpot/Core/Models/CafeInsight.swift \
    QuietSpot/Core/Models/CafeSnapshot.swift \
    QuietSpot/Core/Models/CafeCheckIn.swift \
    Shared/CafeCheckInTimeFormatter.swift \
    QuietSpot/Core/Services/CommunityPostSiriSnapshot.swift \
    Tests/CommunityPostSiriTests.swift \
    -o "$test_dir/community-siri-tests"
"$test_dir/community-siri-tests"
