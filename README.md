# QuietSpot

QuietSpot is an iOS app for discovering cafés that fit the way you want to
work or relax. Browse café conditions, save favourites, check in with live
updates, and share useful community insights.

## Highlights

- Explore cafés by name, area, and current conditions
- View cafés near you on a map
- Save favourite cafés and see their latest updates
- Share and discover community insights
- Use widgets and Siri shortcuts for quick access

## Requirements

- Xcode 26.2 or later
- iOS 26.2 or later
- A configured Firebase project

## Getting started

1. Clone this repository.
2. Open `QuietSpot.xcodeproj` in Xcode.
3. Select the shared **QuietSpot** scheme.
4. Choose an iOS simulator or a provisioned device.
5. Build and run the app.

Firebase configuration is required for account and cloud features. See
[`project.md`](project.md) for the complete setup and verification details.

## Project documentation

- [`project.md`](project.md) — architecture, folder structure, features, and
  configuration
- [`TESTING.md`](TESTING.md) — unit-test commands, coverage, and manual checks

## Project structure

```text
QuietSpot/
├── QuietSpot/           # Main iOS app
├── QuietSpotWidgets/    # Home Screen widget
├── Shared/              # Code shared with the widget
├── Config/              # App and widget entitlements
├── QuietSpotTests/      # Unit tests
└── QuietSpot.xcodeproj/ # Xcode project
```

## License

This project is maintained as part of the NIBM BSc Computing iOS coursework.
