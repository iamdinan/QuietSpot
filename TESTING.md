# QuietSpot unit tests

The `QuietSpotTests` Xcode target uses Apple's **Swift Testing** framework (`import Testing`, `@Suite`, `@Test`, `#expect`, `#require`). It imports the real app module with `@testable import QuietSpot`. All previous standalone assertion executables and shell runners have been removed.

## Run in Xcode

1. Open `QuietSpot.xcodeproj` and select the shared **QuietSpot** scheme.
2. Select an installed iOS 26.2-or-newer simulator.
3. Choose **Product → Test** (⌘U). Inspect individual suites and parameterized cases in the Test navigator (⌘6).
4. See **Report navigator → latest Test report → Coverage** for coverage enabled by the shared scheme. Coverage includes app code the unit tests do not exercise; it is not a claim of complete feature coverage.

The Test action sets `QUIETSPOT_UNIT_TESTS=1`. In Debug builds the host displays an empty view and skips normal startup, preventing Firebase session restoration, profile transactions, notification setup and widget publication. The normal Run action does not set this flag. Do not remove the Test action's environment variable: it is part of test isolation.

## Run in Terminal

Use an installed simulator name or UDID:

```sh
xcodebuild test \
  -project QuietSpot.xcodeproj \
  -scheme QuietSpot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -disableAutomaticPackageResolution \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
```

Firebase packages must already be resolved for `-disableAutomaticPackageResolution`. Remove that option when setting up a new checkout that needs its initial package download. Unsigned testing is for the simulator; device testing needs the project's signing configuration.

To run one suite, append `-only-testing:QuietSpotTests/NotificationPolicyTests`. No Firebase account, network connection, location permission, App Group entitlement or notification permission is needed to execute these unit tests.

## Coverage by component

| Suite | Behaviour covered |
| --- | --- |
| `CafeStateTests` | Latest-report stats, three-report history limit, clearing stale state, latest-first sorting and timestamp boundaries/clock skew |
| `NotificationPolicyTests` | Silent baseline, each changed stat, identical/repeated/older/undated reports, per-café isolation, favourite/session/location/radius eligibility |
| `NotificationDeliveryTests` | A pending alert survives eligible context refreshes; disabling updates, removing the favourite, leaving the radius, losing location, changing accounts and stopping the monitor cancel delivery |
| `NotificationContentTests` | Natural wording for all noise levels, positive/negative conditions, café identifier and notification sound |
| `OfflineCacheTests` | Unknown empty caches, downloaded data, persistence of server-confirmed empty queries, invalidation and account/café separation |
| `WidgetTests` | Favourite filtering, latest-three ordering, status precedence, complete stat/date mapping, snapshot persistence, unchanged-save behaviour, sign-out clearing and corrupted/missing storage |
| `SiriResponseTests` | Account/report states, incomplete records, newest favourite only, all spoken stats, saved-data age and refresh guidance |
| `CommunitySnapshotTests` | Newest-post selection, author/café mapping, loading/failure/empty states, metadata fallbacks, author edits and JSON round-trips |
| `ProfilePhotoTests` | JPEG output, 512-pixel limit with aspect-ratio preservation and rejection of corrupt input |
| `AuthenticationMessageTests` | Credential privacy, recovery guidance, unknown-error fallback and test-host isolation |

## Verification

Verified on October 5, 2026 with Xcode 26.2 on the iPhone 17 Pro simulator running iOS 26.3: **40 tests in 10 suites passed**, including all parameterized cases. The simulator build and `git diff --check` also passed. ImageIO can print thumbnail errors during corrupt-photo cases; those cases intentionally expect an error, and their Swift Testing results pass.

## Design and maintenance

- Fixed dates and `en_US_POSIX` isolate age expectations from the clock and device locale. Coordinates are fixed, not simulator location readings.
- Persistence tests create unique temporary directories and UserDefaults domains, then clean them up. They do not touch production App Group files or standard preferences.
- Tests that call app types isolated to the main actor use `@MainActor`. Swift Testing may interleave async cases, so every case owns its monitor, delivery gate and storage.
- Notification delivery uses the monitor's injected sender and continuations to pause at the permission-check suspension point. It uses no sleeps, timing guesses or real notifications. A one-minute limit detects a hung delivery test.
- Notification wording calls the same content builder used by the real sender; scheduling/permission APIs remain separate.
- Add tests to the `QuietSpotTests` folder, which Xcode synchronizes with the test target. Use a descriptive `@Test` name, test observable behaviour and add parameterized arguments where the same rule applies to multiple inputs.

## Manual integration checks

These require system services or a configured Firebase backend and are not mocked by this unit suite:

- Authentication: create/sign in/reset/sign out, restore a session and verify Firestore rules for different accounts.
- Offline: load data online, keep the session signed in, disconnect the Mac and relaunch the simulator. Check cached photos/profiles/favourites/reports/posts, disabled saving actions and reconnect recovery.
- Notifications: allow notifications and location access, favourite a café inside the radius, keep the app active and submit a **new** check-in with at least one changed stat. Confirm a banner; identical stats intentionally remain silent. Test disabled/out-of-radius cases too.
- Widgets and Siri: provision the shared App Group, add the widget, sync favourites, and execute both App Shortcuts. Verify account clearing, foreground/background behaviour and spoken output.
- UI/accessibility: tab navigation, Dynamic Type, VoiceOver, colour appearance and permission prompts.

References: [Swift Testing](https://developer.apple.com/documentation/testing), [adding tests to an Xcode project](https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project), [test parallelization](https://developer.apple.com/documentation/testing/parallelization).
