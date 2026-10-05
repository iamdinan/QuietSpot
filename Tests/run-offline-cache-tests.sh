#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/quietspot-offline.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -module-cache-path "$test_dir/module-cache" \
    QuietSpot/Core/Services/OfflineQueryCache.swift \
    Tests/OfflineQueryCacheTests.swift \
    -o "$test_dir/offline-cache-tests"
"$test_dir/offline-cache-tests"
