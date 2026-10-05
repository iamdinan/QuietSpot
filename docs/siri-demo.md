# QuietSpot Siri demo

QuietSpot uses App Intents and App Shortcuts to expose **Check Favourite Café Stats** to Siri and Shortcuts. No legacy SiriKit extension or extra backend is required. The action returns text and a Siri dialog with the newest saved favourite café's name, area, four stats, and report age. It reads the same App Group snapshot as the widget; it does not fetch fresh Firestore data.

## Demo steps

1. Build and run the `QuietSpot` scheme. On a physical device, use the configured App Group `group.dinan.QuietSpot` and enable Siri in the device's settings.
2. Sign in, favourite a café, and wait for its stats to appear in Home's pulse block. A café needs a check-in to demonstrate the four-stat response.
3. Ask Siri: **“Check my favourite cafés in QuietSpot.”** Alternative phrases are **“Check my favorite cafes in QuietSpot”** and **“Check cafe stats in QuietSpot.”** This action reads the latest single favourite, even though the phrase says cafés.
4. Verify Siri reports the same café and stats as the first item in the pulse block, plus the report age and a reminder to open QuietSpot to refresh.
5. For deterministic testing, open Shortcuts, find QuietSpot under App Shortcuts, and run **Café Stats**. You can also add **Check Favourite Café Stats** to a shortcut followed by **Show Result** to inspect its returned text. This is useful if Siri is unavailable in the simulator.
6. Check the empty-favourites, no-check-ins, and signed-out responses. Unlock the device when prompted; the intent requires device authentication before reading saved favourites.

`QuietSpotShortcuts` registers the Siri phrases, and launch updates shortcut parameters. Missing data, loading, errors, incomplete reports, and signed-out snapshots return clear guidance rather than fabricated conditions. No app UI opens automatically; the action runs in the background using the latest app-synced snapshot.

## Verification

Run `sh Tests/run-siri-response-tests.sh` to check the response text, all four stats, timestamp ageing, and fallback states. Building the app also validates App Intent and App Shortcut metadata. Siri phrase recognition and spoken delivery require a manual device/simulator test; a successful build does not verify those interactions.
