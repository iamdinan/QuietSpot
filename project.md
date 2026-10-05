# QuietSpot

## Project description

QuietSpot is an iPhone and iPad app for finding cafés that suit focused work or a relaxed coffee break. Users can explore cafés, check their latest conditions, save favorites, and share experiences with the community.

The app uses **SwiftUI** with a feature-based **MVVM** architecture. **Firebase Authentication** manages accounts, **Cloud Firestore** stores app data, and **MapKit** shows nearby cafés. **WidgetKit** and **App Intents** provide widgets and Siri shortcuts. The current deployment target is **iOS 26.2**.

## Folder structure

```text
QuietSpot/
├── QuietSpot.xcodeproj/           # Xcode project and shared app scheme
├── QuietSpot/                    # Main app
│   ├── App/                      # Entry point, navigation, tabs, Firebase config
│   │   └── Intents/              # Siri shortcuts
│   ├── Core/                     # Code shared across features
│   │   ├── Models/               # Café, check-in, community, and profile data
│   │   ├── Services/             # Firebase, caching, photos, and notifications
│   │   ├── ViewModels/           # Shared café and image state
│   │   ├── Components/           # Reusable café cards, feeds, and avatars
│   │   ├── DesignSystem/         # Colors, controls, and layout helpers
│   │   └── Location/             # Location tracking and permissions
│   ├── Features/                 # Screen-specific views and view models
│   │   ├── Welcome/              # Welcome screen
│   │   ├── Authentication/       # Sign-in, registration, and password reset
│   │   ├── Home/                 # Favorite café pulse and café browsing
│   │   ├── Explore/              # Search and filters
│   │   ├── CafeDetails/          # Café details and check-in form
│   │   ├── Community/            # Insight feed and post composer
│   │   ├── Map/                  # Nearby cafés and radius controls
│   │   └── Profile/              # Profile editing, personal insights, settings
│   └── Assets.xcassets/          # App icon, welcome image, and colors
├── QuietSpotWidgets/             # Favorite café pulse widget
├── Shared/                       # Shared widget data and time formatting
├── Config/                       # App/widget entitlements and widget settings
├── QuietSpotTests/               # Swift Testing unit tests
├── TESTING.md                    # Test commands and manual checks
└── project.md                    # Project overview
```

Views display the UI, view models manage state, and services handle data and system operations. Feature-specific code stays in `Features`; reusable code belongs in `Core`.

## Features

The main tabs are **Home, Explore, Community, Map, and Profile**.

### Accounts and sign-in

- Create an account with a display name, email, and password; sign in through Firebase Authentication.
- Restore existing sessions automatically, request password-reset emails, and confirm before signing out.
- Show loading and error feedback during authentication. Face ID sign-in is currently a simulator-only prototype using temporary in-memory credentials.

### Home and favorites

- The **Favorite café pulse** shows the latest conditions from up to three favorite cafés, ordered by their latest check-ins.
- Separate **Your favorite cafés** and **All cafés** sections display photo cards with three cafés per page.
- Save or remove favorites using the heart on café details. Favorites belong to the signed-in account and are shared across screens.
- Pull to refresh café metadata. Open any café card to view its details.

### Explore

- Search by café name or area and browse results with five cafés per page.
- Filter for **Quiet**, **Strong Wi-Fi**, **Outlets free**, and **Uncrowded**. Selected filters combine, so a café must satisfy all of them.
- Show an empty-results state when no cafés match; clear filters to broaden the results.

### Café details and check-ins

- View a café's photo, name, area, description, favorite status, and latest three check-ins with their report times.
- Submit current conditions through **Check in here**: noise (**Quiet / Moderate / Loud**), Wi-Fi (**Strong / Spotty**), outlets (**Free / Full**), and crowd (**Uncrowded / Crowded**).
- Live check-in listeners update café conditions across the app. Cafés without reports display **No check-ins yet**.
- Confirm submissions only after Firebase acknowledges them. Failed submissions keep the form open; unavailable photos show a placeholder and a retry action on details.

### Community

- Browse insights from newest to oldest, with the author's name/photo, café, post age, and post text.
- Share an insight about a favorite café. Posts must contain nonblank text and stay within 2,000 characters.
- Like or unlike posts; each account can have one like per post, and counts update through Firestore.
- Preserve drafts when sharing fails and ask before discarding them. **My insights** in Profile shows the current user's posts; post editing and deletion are not implemented.

### Map and nearby cafés

- View café pins and open café details from the map. Center the map on your location when permission is available.
- Adjust the radius from **1–10 km**, with a **5 km** default. The proximity circle and visible café pins follow the selected radius.
- Show a labeled Colombo preview while location is unavailable, with feedback for denied permission or approximate location.

### Profile and settings

- Edit your display name and add, replace, or remove a profile photo using the system photo picker.
- Updated names and photos appear on community posts, including previously shared insights. Unsaved profile changes require discard confirmation.
- Settings includes notification preferences, VoiceOver status and setup guidance, the Face ID prototype toggle, and app information.

### Café update notifications

- Receive local alerts when noise, Wi-Fi, outlets, or crowd conditions change at a favorite café within the selected map radius.
- Alerts require notification permission, location access, the café-update preference, and an active app. Initial data loads and repeated unchanged reports remain silent.
- Monitoring works across signed-in tabs while the app is active. Background push delivery while the app is closed is not implemented.

### Offline browsing and photos

- Browse previously downloaded content offline; a banner identifies offline or cached data. Actions that require a connection are disabled.
- Online café refreshes read current server records, including deletions; reconnecting triggers another data load.
- Café and profile photos use Base64 data stored in Firestore. A photo document at `cafeImages/{cafeID}` must match its café document at `cafes/{cafeID}`.

### iPad layouts and accessibility

- Center text, forms, and feeds at readable widths. Café cards use adaptive columns on wider screens and a single column in compact layouts or at accessibility text sizes.
- Use consistently cropped photos, a full-width welcome image, and focused form-sized editing sheets.
- Follow system light/dark appearance and support Dynamic Type and VoiceOver through semantic text, headings, labels, and status descriptions.

### Widgets and Siri shortcuts

- The **Favorite café pulse** widget supports small, medium, and large sizes, showing saved conditions and the age of check-ins for favorite cafés.
- Siri shortcuts can read saved favorite café stats or the latest saved community post, including its author and café.
- Both use data last synced by QuietSpot rather than fetching fresh Firebase data independently. Open the app to refresh their content.
