#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/quietspot-siri-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -module-cache-path "$test_dir/module-cache" \
    Shared/PulseWidgetData.swift \
    QuietSpot/Core/Models/CafeCheckInTimeFormatter.swift \
    QuietSpot/Core/Services/FavoriteCafeSiriResponse.swift \
    Tests/FavoriteCafeSiriResponseTests.swift \
    -o "$test_dir/siri-tests"
"$test_dir/siri-tests"
