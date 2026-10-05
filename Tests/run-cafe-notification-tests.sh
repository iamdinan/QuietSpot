#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/quietspot-notifications.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -module-cache-path "$test_dir/module-cache" \
    QuietSpot/Core/Models/CafeCheckIn.swift \
    QuietSpot/Core/Models/CafeSnapshot.swift \
    QuietSpot/Core/Models/CafeStatUpdateTracker.swift \
    QuietSpot/Core/Models/CafeUpdateNotificationContext.swift \
    Tests/CafeNotificationPolicyTests.swift \
    -o "$test_dir/notification-tests"
"$test_dir/notification-tests"

xcrun swiftc -module-cache-path "$test_dir/module-cache" \
    QuietSpot/Core/Models/CafeCheckIn.swift \
    QuietSpot/Core/Models/CafeSnapshot.swift \
    QuietSpot/Core/Models/CafeStatUpdateTracker.swift \
    QuietSpot/Core/Models/CafeUpdateNotificationContext.swift \
    QuietSpot/Core/Services/CafeUpdateNotificationMonitor.swift \
    Tests/CafeNotificationDeliveryTests.swift \
    -o "$test_dir/delivery-tests"
"$test_dir/delivery-tests"
