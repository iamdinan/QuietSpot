# QuietSpot project guide

Last reviewed: October 1, 2026. This document describes the current repository and distinguishes implemented behavior from proposed backend work. Update it when screens, persistence, or Firebase services change.

## App overview

QuietSpot is a SwiftUI café discovery and conditions-monitoring app. Users find cafés, save favorites, report conditions through check-ins, and share café insights with the community. Sample cafés are located around Colombo, Sri Lanka.

The five tabs are always ordered **Home, Explore, Community, Map, Profile**. Firebase Authentication is connected; café and community content is still a local prototype. Do not assume that displaying a successful check-in or post means it has been saved to a server.

### Current implementation status

| Capability | Current behavior |
| --- | --- |
| Registration, sign-in, sign-out | Firebase email/password Authentication |
| Session restoration | Firebase auth-state listener drives the app shell |
| Password reset | Firebase sends the reset email; user completes the reset through its link |
| Display name | Saved to Firebase Authentication at registration and when edited |
| Profile photo | System photo picker; resized image held locally, not uploaded |
| Cafés and favorites | Five sample cafés; three initially favorited; shared in-memory state |
| Check-ins | Update café state locally; retain the latest three reports in the prototype |
| Community posts and likes | Local sample feed and user-created posts; no remote persistence |
| Map | MapKit and Core Location with local café coordinates and radius filtering |
| Notifications | Real permission request/status plus a stored preference; no delivery pipeline |
| Face ID/Touch ID | Availability display only; no biometric sign-in or app lock |
| Firestore, Storage, Cloud Functions, FCM | Not integrated into the app yet |

Sample/local content resets when the authenticated tab shell is recreated, including after sign-out/sign-in or app relaunch. Local settings use device-wide `AppStorage`, not account-specific cloud settings.

## Technology and Xcode setup

- SwiftUI app in `QuietSpot.xcodeproj`; use the `QuietSpot` scheme.
- Current project deployment target: iOS 26.2. Xcode 26.2 was used for the verified simulator build. This is the current configuration, not a claim that every feature requires iOS 26.2.
- Bundle identifier: `dinan.QuietSpot` (case-sensitive).
- Apple frameworks: MapKit, CoreLocation, PhotosUI, ImageIO, UserNotifications, LocalAuthentication, and Observation/Combine.
- Firebase products linked: `FirebaseCore` and `FirebaseAuth` only.
- Firebase repository: `https://github.com/firebase/firebase-ios-sdk.git`.
- Swift Package Manager requirement: up to the next major version from `12.0.0`; current `Package.resolved` pins Firebase `12.19.2`.
- The app folder is an Xcode file-system-synchronized group. New Swift files inside it are normally included automatically.

An Xcode application using Swift Package Manager dependencies does **not** need to adopt a standalone package's `Sources/`, `Tests/`, and `Package.swift` layout.

## Folder structure

```text
QuietSpot/
├── project.md
├── QuietSpot.xcodeproj/
│   ├── project.pbxproj
│   └── project.xcworkspace/xcshareddata/swiftpm/Package.resolved
└── QuietSpot/
    ├── App/
    │   ├── QuietSpotApp.swift             # SwiftUI entry point
    │   ├── AppDelegate.swift              # Firebase startup hook
    │   ├── ContentView.swift              # Authentication/navigation shell
    │   ├── MainTabView.swift              # Five tabs and shared sample state
    │   ├── AppRoute.swift
    │   ├── AppAppearance.swift
    │   └── GoogleService-Info.plist        # Project-specific Firebase config
    ├── Core/
    │   ├── Models/                        # CafeSnapshot, CafeCheckIn,
    │   │                                  # CafeInsight, UserProfile
    │   ├── Services/FirebaseConfiguration.swift
    │   ├── Location/LocationProvider.swift
    │   ├── SampleData/                    # CafeSampleData, CommunitySampleData
    │   ├── Components/
    │   │   ├── Cafe/                      # Cards, status pills, thumbnails, pager
    │   │   ├── Community/                 # CafeInsightCard, CafeInsightFeed
    │   │   ├── Profile/ProfileAvatar.swift
    │   │   └── MapRadiusControl.swift
    │   └── DesignSystem/
    │       ├── AppColor.swift
    │       └── Components/                # PrimaryButton, TextLinkButton,
    │                                      # InputFieldStyle
    ├── Features/
    │   ├── Welcome/Views/
    │   ├── Authentication/
    │   │   ├── Views/                     # SignIn, CreateAccount, ForgotPassword,
    │   │   │                              # AuthenticationFeedback
    │   │   └── ViewModels/AuthenticationViewModel.swift
    │   ├── Home/Views/
    │   ├── Explore/Views/
    │   ├── Community/Views/
    │   ├── CafeDetails/Views/              # Details and check-in composer
    │   ├── Map/Views/
    │   └── Profile/Views/                 # Profile, EditProfile, MyInsights,
    │                                      # Settings, NotificationSettings
    └── Assets.xcassets/                   # Hero/café images and adaptive colors
```

### Organization rules

- Keep screen-specific code inside its feature. Shared models, reusable UI, and cross-feature services belong in `Core`.
- Reuse `CafeStatusCard`, `CafeStatusGrid`, `CafePager`, `CafeInsightFeed`, and `ProfileAvatar` instead of duplicating them.
- Add view models when a feature gains asynchronous data loading, subscriptions, or substantial state/business logic. Do not create empty layers merely to match a template.
- Authentication currently has a view model. Other screens mostly use small local state and bindings; full MVVM across every feature is not yet implemented.
- Keep Firebase SDK calls outside presentation code where practical. Future Firestore services should feed feature view models rather than each row directly querying Firebase.

## UI and interaction requirements

Follow [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines). Native controls are a starting point, not proof of complete compliance: test layouts, interaction states, accessibility, and contrast on-device.

- Prefer native `TabView`, `NavigationStack`, `Form`, `List`, `Picker`, `Toggle`, searchable fields, and focused sheets.
- Support system/light/dark appearance with semantic backgrounds and adaptive colors.
- Use Dynamic Type text styles, readable wrapping, and approximately 44 × 44-point or larger interactive targets.
- Communicate status with text/icons as well as color. Give icon-only actions descriptive accessibility labels.
- Keep photos consistently cropped and bounded. Avoid unnecessarily large stat tiles or oversized decorative cards.
- Preserve drafts with discard confirmation where appropriate. Provide loading, empty, permission-denied, and error states.
- Current validation is intentionally limited: basic required auth fields, Firebase error handling, nonblank insight text, and nonblank edited display names. Comprehensive data validation must be implemented alongside backend rules.

### Exact café status vocabulary

All four factors have equal visual importance; noise is **not** a primary highlighted stat.

| Factor | Allowed UI values | Color treatment |
| --- | --- | --- |
| Noise | Quiet, Moderate, Loud | Green, amber, red respectively |
| Wi-Fi | Strong Wi‑Fi, Spotty Wi‑Fi | Green, red |
| Outlets | Outlets free, Outlets full | Green, red |
| Crowd | Uncrowded, Crowded | Green, red |

Do not introduce extra statuses such as “moderate crowd.” The shared status component uses compact two-column pills, switching to one column at accessibility text sizes.

### Screen behavior

- **Landing:** café hero image, app name/title, Sign in to continue, and an appearance toggle. The image extends into the top safe area; the toggle remains below the sensor/notch area.
- **Sign in:** welcome text, email/password fields, Forgot password, and Create an account. Successful authentication opens Home.
- **Create account:** display name, email, password, and Create account. Firebase stores the display name without requiring a Firestore collection.
- **Forgot password:** email field, reset button, loading/error feedback, and a neutral confirmation that does not reveal whether the address is registered.
- **Home:** exactly three sections: favorite café pulse (latest three favorites, all four stats, no pagination); all favorites (three per page); all cafés (three per page). The last two reuse the same café card style. Updating a favorite promotes it in the pulse ordering.
- **Explore:** café/area search and four positive filters: Quiet, Strong Wi‑Fi, Outlets free, Uncrowded. Active filters combine with AND logic. Café results paginate five per page.
- **Café details:** image, name/area, favorite heart, description, latest three check-ins, and Check in here. This one reusable screen opens for cafés from different tabs.
- **Check-in composer:** selects only the allowed status values. Submission currently updates local café state and shows confirmation.
- **Community:** newest-first insights from all sample cafés. The compose sheet only offers favorites; blank/whitespace-only text cannot be shared. No community pagination is implemented yet.
- **Post card:** café header/thumbnail/link, compact author/time line, insight text, and a separate like footer. Thumbs-up means like; hearts remain reserved for café favorites. Tap again to undo the local like. Likes do not change feed ordering.
- **Profile:** centered avatar/display name/Edit profile header; left-aligned My insights with count, Settings, and confirmed Sign out.
- **My insights:** filters posts by the current profile's user ID and reuses Community's cards/feed. Likes are shared between these screens. Post editing/deletion is not implemented.
- **Edit profile:** add/change/remove a photo using PhotosPicker, edit display name, Save/Cancel, draft-discard protection, and photo-load errors. Name changes persist to Firebase Auth; photo changes remain in-memory. Current-user posts render the shared profile name/photo so older local posts update too.
- **Settings:** appearance picker, Notifications, biometric availability, About QuietSpot. Map radius is controlled in Map, not Settings.
- **Map:** current location, proximity circle, and matching sample café pins. Radius is 1–10 km in 1 km steps, default 5 km. Without location, show a clearly labeled Colombo preview instead of pretending it is the user's location. Handle denied/approximate location; stop updates when Map is not active.

Initial sample cafés: The Glass House, Common Grounds, The Coffee Stop, Kopi Kade, and Whight & Co. The Glass House, Common Grounds, and Kopi Kade start as favorites. Their imagery, descriptions, and status data are prototype content, not verified live café information.

## Current authentication implementation

```text
QuietSpotApp → AppDelegate → FirebaseConfiguration
                                  ↓
                          Configure Firebase SDK

Auth screen → AuthenticationViewModel → Firebase Authentication
                       ↓
                User ID / profile state
                       ↓
               ContentView → MainTabView
```

Key files and responsibilities:

- `App/QuietSpotApp.swift`: attaches the application delegate.
- `App/AppDelegate.swift`: invokes Firebase configuration at launch.
- `Core/Services/FirebaseConfiguration.swift`: reads the bundled plist, checks bundle-ID compatibility, avoids duplicate configuration, and reports missing/mismatched setup without entering a fake authenticated session.
- `Features/Authentication/ViewModels/AuthenticationViewModel.swift`: `@MainActor`, `@Observable`; auth-state listener, asynchronous sign-in/registration/reset/name updates, sign-out, busy state, session/profile mapping, and readable errors.
- `App/ContentView.swift`: owns and injects authentication state, restores sessions, chooses authenticated/unauthenticated navigation, and presents account notices.
- `App/MainTabView.swift`: shares sample cafés/posts and the authenticated profile across tabs. The shell is keyed by user ID so another account does not inherit the previous shell's local content.

`UserProfile.id` and post `authorID` now use string IDs compatible with Firebase Authentication UIDs. Do not use a display name as an identifier. The prototype's sample authors have copied names without real accounts; those names must be replaced/resolved through user profiles when the community backend is introduced.

### Firebase console and Xcode checklist

1. Create/select the Firebase project named QuietSpot. Its generated project ID is not necessarily the same as its display name.
2. Register the iOS app using `dinan.QuietSpot`.
3. Download the real `GoogleService-Info.plist`; it currently resides in `QuietSpot/App/`. Ensure target membership/resource inclusion and keep the filename unchanged. Never invent placeholder credentials.
4. Enable Authentication's Email/Password provider. Email-link sign-in is not used.
5. Open `QuietSpot.xcodeproj`, wait for package resolution, select the scheme/device, and run. Packages are already configured; do not add duplicates.
6. Register with an email you control and check Firebase Authentication's Users page. Test sign-out/sign-in, session restoration after relaunch, wrong-password handling, password-reset delivery, and display-name persistence.

Package references and linked products are recorded in `project.pbxproj`; dependency versions are recorded in `Package.resolved`. Adding the SDK through Xcode's package UI produces the same kind of configuration. See [Firebase's Apple setup guide](https://firebase.google.com/docs/ios/setup) and [email/password guide](https://firebase.google.com/docs/auth/ios/password-auth).

Registration/sign-in were confirmed working by the user. An unsigned simulator build passed during integration. Password reset is wired up, but this documentation does not claim that email delivery was independently tested. There is no automated test target currently configured.

## Proposed Firebase/backend structure — not implemented

Add collections incrementally as each feature is connected. Firebase Auth accounts already exist independently of Firestore documents. Use Firestore for structured records, Cloud Storage for images, and trusted backend operations where derived data must be protected.

```text
users/{userID}                         # Community-visible profile
  displayName, photoPath, createdAt, updatedAt
  favorites/{cafeID}
    createdAt
  private/settings                    # Owner-only document
    cafeUpdatesEnabled, mapRadiusKilometers

cafes/{cafeID}
  name, area, description, imagePath
  location: GeoPoint, geohash
  latestStatus:
    noise, wifi, outlets, crowd, checkedAt, checkInID

checkIns/{checkInID}
  cafeID, authorID, noise, wifi, outlets, crowd, createdAt

posts/{postID}
  cafeID, authorID, text, createdAt, updatedAt, likeCount
  likes/{userID}
    createdAt
```

These are recommended application-level paths/fields, not deployed schema. Collection paths alternate between collections and documents; `private/settings` is a subcollection/document under a user.

### Data and query rules

- Use stable Firestore document IDs, not freshly generated UUIDs on every fetch. Current sample café/check-in IDs are local UUIDs and need migration when data loading is added.
- Store canonical status values (`quiet/moderate/loud`, `strong/spotty`, `free/full`, `uncrowded/crowded`), mapping them to UI labels. Enforce exactly these values server-side.
- Use server timestamps for reports/posts. The current display strings and `updateOrder` sorting are prototype shortcuts, not backend timestamp fields.
- Store check-ins separately. Café details query by `cafeID`, descending `createdAt`, limit three. Keeping only three local records must not become the server's entire history policy.
- Store a latest-status summary on each café for efficient Home/Explore loading. A trusted, retry-safe operation should maintain it and prevent an older check-in from overwriting a newer summary.
- Read a user's favorite IDs and their café summaries. Sort eligible summaries by actual last-check-in time for the pulse widget; do not maintain a second independent favorite list.
- Query posts by descending `createdAt`; filter My insights by `authorID`. Add required composite indexes and cursor-based pagination instead of downloading an unbounded collection. Five posts per page is a possible future choice, not current behavior. See [Firestore pagination](https://firebase.google.com/docs/firestore/query-data/query-cursors).
- Resolve/cache authors from `users/{authorID}` so profile updates affect historical posts. Firestore does not automatically join profiles into post results; the data layer must load and refresh them.
- Make favorite document IDs the café ID and like document IDs the authenticated UID to avoid duplicates. Like records are the source of truth; clients must not freely overwrite aggregate counts. Maintain `likeCount` transactionally or through an idempotent backend mechanism.
- For Firestore Standard nearby searches, use geohash query bounds, deduplicate candidates, and filter by exact distance. Do not query every café nationwide for each radius adjustment. See [Firebase geoqueries](https://firebase.google.com/docs/firestore/solutions/geoqueries).
- Current search uses local substring matching. Decide the remote search strategy separately; it should not be assumed to translate directly into an indexed Firestore query.

### Photos, preferences, and notifications

- Put image bytes in Cloud Storage (for example `profilePhotos/{userID}/...` and `cafeImages/{cafeID}/...`); store paths in Firestore. Avoid embedding photos/base64 in Firestore profile documents.
- Cloud Storage currently requires a Blaze billing account; eligible no-cost allowances vary by bucket/location. Do not promise universally free photo storage. See [Storage billing requirements](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024).
- When Firestore profiles are added, explicitly choose the source of truth and synchronization policy for display names; the current source is Firebase Auth. Changing this must preserve name updates on historical posts.
- Cache radius/settings locally and optionally synchronize account preferences. Appearance may remain device-specific. Biometric enrollment is managed by iOS, not Firebase.
- Nearby counts can be computed locally when location/data are available. A scheduled local notification cannot fetch fresh Firebase data when it fires. Future background café-update alerts need a deliberate backend/FCM/APNs design; do not rely on continuous Firestore listening while the app is suspended.
- Actual push delivery, token registration, background tasks, geofenced notifications, and notification deduplication are not implemented.

## Security and privacy requirements

- Never store passwords in Firestore or app preferences; Firebase Authentication handles credentials.
- Keep email and private settings out of community-visible profile documents. Only authenticated owners may change their profile, favorites, preferences, posts, and like records, according to feature rules.
- Before connecting collections, deploy deny-by-default Firestore/Storage rules with explicit permitted reads/writes and field/type/enum validation. Restrict café metadata and derived summaries/counts to trusted writers.
- Creating a community post should verify that its `authorID` is the authenticated user and that the selected café is favorited at creation time. Removing a favorite later should not implicitly delete historical posts.
- Plan moderation/reporting, account deletion, and related-data cleanup before a public launch. Deleting a Firestore parent document does not automatically delete its subcollections. See [Firestore data model](https://firebase.google.com/docs/firestore/data-model).
- Firebase client configuration identifies the project; a Firebase-only API key is not an administrator credential. Still review API restrictions, quotas, and usage. Never reuse it for unrelated paid APIs, particularly Gemini. See [Firebase API-key guidance](https://firebase.google.com/docs/projects/api-keys).
- A GitHub key warning is a prompt to inspect restrictions and usage, not proof of compromise. If the key grants inappropriate access or is misused, replace/restrict it, update local configuration, and test before retiring the old key.
- Excluding the plist from a public repository is an optional project-sharing policy; this document does not change `.gitignore` or Git history. Exclusion does not revoke a key or remove previously committed copies.
- Never commit service-account JSON credentials, private signing/APNs keys, passwords, or privileged backend tokens. Do not paste actual configuration values into this documentation.
- Consider App Check for supported services and abuse/rate controls as backend integration progresses. Security must not depend on hiding values bundled in an iOS app.

## Development handoff

Continue feature-by-feature: add the required Firebase product/service, implement its data layer and rules, replace sample data for that feature, and verify persistence and cross-account isolation. Keep the folder structure simple and update this document to reflect what actually ships.

UI checks should include light/dark mode, large accessibility text, small iPhone layouts, readable image crops, navigation/back behavior, empty favorites/results/posts, permission-denied location/notifications, and network failures. Authentication checks should include session restoration, failed credentials, duplicate registration, reset email, name changes, and confirmed sign-out. A successful build alone is not evidence that every live backend flow works.
