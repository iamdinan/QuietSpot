#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/quietspot-check-in-time.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -module-cache-path "$test_dir/module-cache" \
    Shared/CafeCheckInTimeFormatter.swift \
    Tests/CafeCheckInTimeFormatterTests.swift \
    -o "$test_dir/check-in-time-tests"
"$test_dir/check-in-time-tests"
