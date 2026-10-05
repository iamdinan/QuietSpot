#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/quietspot-widget-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -module-cache-path "$test_dir/module-cache" \
    Shared/PulseWidgetData.swift \
    QuietSpot/Core/Models/CafeCheckIn.swift \
    QuietSpot/Core/Models/CafeSnapshot.swift \
    QuietSpot/Core/Services/PulseWidgetPublisher.swift \
    Tests/PulseWidgetTests.swift \
    -o "$test_dir/widget-tests"
"$test_dir/widget-tests"
