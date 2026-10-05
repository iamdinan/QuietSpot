# Favourite café pulse widget

QuietSpot includes a WidgetKit extension named `QuietSpotWidgets`, embedded in the app. Its design follows Home’s Favourite café pulse: brand-green header, café name, report age, and equally weighted noise, Wi-Fi, outlet, and crowd pills.

- Small: newest favourite café, with compact stat labels and full VoiceOver values.
- Medium: newest favourite café, area, cup icon, and all four full stat labels.
- Large: up to three favourite cafés, ordered by newest check-in, matching Home.
- Empty states: sign in, save a café, loading, unavailable data, or open the app to sync.
- Tapping the widget opens QuietSpot. There is no per-café deep link or widget configuration picker yet.

## Setup and use

1. Open `QuietSpot.xcodeproj` and select the `QuietSpot` scheme. The app builds and embeds the extension automatically.
2. For a physical device, select the same signing team for `QuietSpot` and `QuietSpotWidgets`. Both targets must have the App Groups capability with `group.dinan.QuietSpot` registered and enabled. Entitlement files are in `Config/`; changing the group also requires changing `PulseWidgetStore.appGroup` in `Shared/PulseWidgetData.swift`.
3. Run QuietSpot, sign in, and save favourite cafés. Wait for their check-ins to load.
4. Long-press the Home Screen, choose Edit → Add Widget, search for QuietSpot, and choose Favorite café pulse in the desired size.
5. Change a favourite or submit a new check-in while the app is open, then check the widget. Sign out and verify the widget eventually replaces the previous favourites with its sign-in state.

The widget reads an atomic JSON snapshot in the App Group container. `PulseWidgetPublisher` exports the same latest three favourites as Home and requests a timeline reload only when the data changes. Authentication changes clear the previous account’s snapshot before another account loads. No auth tokens, user profiles, or Firebase SDK are included in the extension.

Report-age labels use minute-spaced timeline entries, with a new cached timeline requested after an hour. The widget shows the last app-synced data; it does not fetch fresh Firestore reports while QuietSpot is closed. WidgetKit controls reload timing, so app changes and sign-out may not appear on the Home Screen immediately. See [Apple’s widget refresh guidance](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date/).

## Verification

- Debug simulator build of the app and embedded extension passed.
- `sh Tests/run-pulse-widget-tests.sh` checks favourite selection/order, report dates/stats, snapshot persistence, unchanged-data suppression, account clearing, missing reports, loading/errors, corrupt cache, and missing App Group configuration.
- Small, medium, large, and empty-state layouts were inspected using the widget’s SwiftUI view in a separate simulator preview app. Xcode WidgetKit previews are also included in `FavoritePulseWidget.swift`.
- Live Home Screen placement and app-to-widget syncing still need manual verification. Preview sample cafés are only used by placeholders/gallery previews; runtime widgets show stored app data or an empty state.
