# QuietSpot project guide

Last reviewed: October 2, 2026. This document describes the current repository and distinguishes implemented behavior from proposed backend work. Update it at the end of a coding session when requested, rather than after every code change.

## App overview

QuietSpot is a SwiftUI café discovery and conditions-monitoring app. Users find cafés, save favorites, report conditions through check-ins, and share café insights with the community. Café metadata loads from Firestore; the first configured café is Barista - Ward Place in Colombo, Sri Lanka. Café photos use separate Firestore Base64 image documents for the limited prototype (around 20 photos). Metadata loading was confirmed working on October 1; the Base64 loader added October 2 still requires user verification.

The five tabs are always ordered **Home, Explore, Community, Map, Profile**. Firebase Authentication and café metadata reads are connected. Favorites, check-ins, and community posts/likes are still local. Do not assume that displaying a successful check-in or post means it has been saved to a server.

### Current implementation status

| Capability | Current behavior |
| --- | --- |
| Registration, sign-in, sign-out | Firebase email/password Authentication |
| Session restoration | Firebase auth-state listener drives the app shell |
| Password reset | Firebase sends the reset email; user completes the reset through its link |
| Display name | Saved to Firebase Authentication at registration and when edited |
| Profile photo | System photo picker; resized image held locally, not uploaded |
| Cafés and favorites | Firestore metadata and separate Base64 image reads; favorites are session-only and initially empty |
| Check-ins | Update café state locally; retain the latest three reports in the prototype |
| Community posts and likes | Initially empty; user-created posts/likes are session-only |
| Map | MapKit and Core Location with Firestore café coordinates and local radius filtering |
| Notifications | Real permission request/status plus a stored preference; no delivery pipeline |
| Face ID | Simulator-only biometric-assisted Firebase sign-in; reuses the latest successfully authenticated email/password held in memory after a matching face |
| Firestore | Metadata reads at tab startup and Home pull-to-refresh; simulator build passed and live loading confirmed working by the user |
| Storage, Cloud Functions, FCM | Not integrated into the app yet |

Sample/local content resets when the authenticated tab shell is recreated, including after sign-out/sign-in or app relaunch. Local settings use device-wide `AppStorage`, not account-specific cloud settings.

## Technology and Xcode setup

- SwiftUI app in `QuietSpot.xcodeproj`; use the `QuietSpot` scheme.
- Current project deployment target: iOS 26.2. Xcode 26.2 was used for the verified simulator build. This is the current configuration, not a claim that every feature requires iOS 26.2.
- Bundle identifier: `dinan.QuietSpot` (case-sensitive).
- Apple frameworks: MapKit, CoreLocation, PhotosUI, ImageIO, UserNotifications, LocalAuthentication, and Observation/Combine.
- Firebase products linked: `FirebaseCore`, `FirebaseAuth`, and `FirebaseFirestore`.
- Café migration is staged: metadata comes from `cafes`; Base64 images come from `cafeImages` with matching document IDs. There is no URL-based image loader or third-party image-hosting dependency. Check-ins and user favorites are not yet persisted remotely.
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
    │   ├── ContentView.swift              # Authentication/navigation shell
    │   ├── MainTabView.swift              # Five tabs and shared café state
    │   ├── AppRoute.swift
    │   ├── AppAppearance.swift
    │   └── GoogleService-Info.plist        # Project-specific Firebase config
    ├── Core/
    │   ├── Models/                        # CafeDocument, CafeSnapshot, CafeCheckIn,
    │   │                                  # CafeInsight, UserProfile
    │   ├── Services/                      # FirebaseConfiguration, CafeService,
    │   │                                  # CafeImageService, SimulatorFaceIDService
    │   ├── ViewModels/                    # CafeViewModel, CafeImageViewModel
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

- `CafeDocument` decodes café metadata (`name`, `area`, `description`, `location`) and the Firestore document ID. `CafeService.fetchCafes()` performs a one-time server read of `cafes`, returns cafés sorted by name, and propagates network/permission/decoding errors. `CafeViewModel` maps these to shared `CafeSnapshot` UI state after sign-in. Refreshes preserve session-only favorites/check-ins by document ID. There is no realtime listener or remote check-in reading yet.
- `CafeImageService` performs individual server reads of `cafeImages/{cafeID}`, decodes Base64 to `Data` and `UIImage`, and shares concurrent requests. Its app-process memory cache is limited to 20 images/20 MiB (eviction limits, not a guaranteed hard memory cap). `CafeImageViewModel` handles loading/errors; reusable `CafeImage` renders photos and retry placeholders. Map-only views do not fetch image documents. The cache is not disk-persistent and image changes require eviction/app restart to refetch a successfully cached photo.

- Keep screen-specific code inside its feature. Shared models, reusable UI, and cross-feature services belong in `Core`.
- Reuse `CafeStatusCard`, `CafeStatusGrid`, `CafePager`, `CafeInsightFeed`, and `ProfileAvatar` instead of duplicating them.
- Add view models when a feature gains asynchronous data loading, subscriptions, or substantial state/business logic. Do not create empty layers merely to match a template.
- Authentication and shared café loading have view models. Other screens mostly use small local state and bindings; full MVVM across every feature is not yet implemented.
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
- **Sign in:** welcome text, email/password fields, Forgot password, and Create an account. For an enabled email with remembered credentials, Use Face ID prompts for simulated biometrics, then signs in through Firebase without asking for the password again. Only successful Firebase authentication opens Home; no confirmation-only step or fake authenticated session is used.
- **Create account:** display name, email, password, and Create account. Firebase stores the display name without requiring a Firestore collection.
- **Forgot password:** email field, reset button, loading/error feedback, and a neutral confirmation that does not reveal whether the address is registered.
- **Home:** exactly three sections: favorite café pulse (latest three favorites, all four stats, no pagination); all favorites (three per page); all cafés (three per page). The last two reuse the same café card style. Updating a favorite promotes it in the pulse ordering.
- **Explore:** café/area search and four positive filters: Quiet, Strong Wi‑Fi, Outlets free, Uncrowded. Active filters combine with AND logic. Café results paginate five per page.
- **Café details:** image, name/area, favorite heart, description, latest three check-ins, and Check in here. This one reusable screen opens for cafés from different tabs.
- **Check-in composer:** selects only the allowed status values. Submission currently updates local café state and shows confirmation.
- **Community:** newest-first session-only insights, initially empty. The compose sheet only offers favorites; blank/whitespace-only text cannot be shared. No community pagination is implemented yet.
- **Post card:** café header/thumbnail/link, compact author/time line, insight text, and a separate like footer. Thumbs-up means like; hearts remain reserved for café favorites. Tap again to undo the local like. Likes do not change feed ordering.
- **Profile:** centered avatar/display name/Edit profile header; left-aligned My insights with count, Settings, and confirmed Sign out.
- **My insights:** filters posts by the current profile's user ID and reuses Community's cards/feed. Likes are shared between these screens. Post editing/deletion is not implemented.
- **Edit profile:** add/change/remove a photo using PhotosPicker, edit display name, Save/Cancel, draft-discard protection, and photo-load errors. Name changes persist to Firebase Auth; photo changes remain in-memory. Current-user posts render the shared profile name/photo so older local posts update too.
- **Settings:** appearance picker, Notifications, Face ID toggle, About QuietSpot. Simulator Face ID enrollment and the latest successfully authenticated email/password remain only in memory and reset when the app restarts. No password-confirmation sheet, Keychain storage, or disk persistence exists. A restored Firebase session without remembered credentials must sign out and sign in with a password before enabling Face ID. Map radius is controlled in Map, not Settings.
- **Map:** current location, proximity circle, and matching Firestore café pins. Radius is 1–10 km in 1 km steps, default 5 km. Without location, show a clearly labeled Colombo preview instead of pretending it is the user's location. Handle denied/approximate location; stop updates when Map is not active.

Sample cafés and community data remain only for SwiftUI previews. The runtime app does not fall back to them on a Firestore error. Cafés without check-ins display “No check-ins yet”; missing conditions are not treated as positive filters. `CafeImage` shares bounded cropping, loading indicators, and photo-unavailable placeholders across cards, thumbnails, and details.

## Current authentication implementation

```text
QuietSpotApp → ContentView.task → AuthenticationViewModel.start()
                                          ↓
                              FirebaseConfiguration
                                          ↓
                              Configure Firebase SDK

Auth screen → AuthenticationViewModel → Firebase Authentication
                       ↓
                User ID / profile state
                       ↓
               ContentView → MainTabView
```

Key files and responsibilities:

- `App/QuietSpotApp.swift`: opens the root `ContentView`; Firebase startup is handled once by the authentication view model's `start()` method.
- `Core/Services/FirebaseConfiguration.swift`: reads the bundled plist, checks bundle-ID compatibility, avoids duplicate configuration, and reports missing/mismatched setup without entering a fake authenticated session.
- `Features/Authentication/ViewModels/AuthenticationViewModel.swift`: `@MainActor`, `@Observable`; auth-state listener, asynchronous sign-in/registration/reset/name updates, simulator Face ID state/actions, sign-out, busy state, session/profile mapping, and readable errors. Successful registration/password sign-in remembers credentials for the simulator prototype. `signInWithFaceID(email:)` waits for a biometric match, uses the remembered password for Firebase sign-in, and updates session state only after Firebase accepts it.
- `Core/Services/SimulatorFaceIDService.swift`: simulator-only LocalAuthentication prompt, enabled-email set, and one in-memory email/password pair. Email matching trims whitespace and ignores case. It neither writes credentials to disk nor bypasses Firebase authentication.
- `App/ContentView.swift`: owns and injects authentication state, restores sessions, chooses authenticated/unauthenticated navigation, and presents account notices.
- `App/MainTabView.swift`: owns the shared café view model, local posts, and the authenticated profile across tabs. Presents café loading/error feedback with retry. The shell is keyed by user ID so another account does not inherit the previous shell's local content.

`UserProfile.id` and post `authorID` now use string IDs compatible with Firebase Authentication UIDs. Do not use a display name as an identifier. The prototype's sample authors have copied names without real accounts; those names must be replaced/resolved through user profiles when the community backend is introduced.

### Firebase console and Xcode checklist

1. Create/select the Firebase project named QuietSpot. Its generated project ID is not necessarily the same as its display name.
2. Register the iOS app using `dinan.QuietSpot`.
3. Download the real `GoogleService-Info.plist`; it currently resides in `QuietSpot/App/`. Ensure target membership/resource inclusion and keep the filename unchanged. Never invent placeholder credentials.
4. Enable Authentication's Email/Password provider. Email-link sign-in is not used.
5. Open `QuietSpot.xcodeproj`, wait for package resolution, select the scheme/device, and run. Packages are already configured; do not add duplicates.
6. Register with an email you control and check Firebase Authentication's Users page. Test sign-out/sign-in, session restoration after relaunch, wrong-password handling, password-reset delivery, and display-name persistence.

Package references and linked products are recorded in `project.pbxproj`; dependency versions are recorded in `Package.resolved`. Adding the SDK through Xcode's package UI produces the same kind of configuration. See [Firebase's Apple setup guide](https://firebase.google.com/docs/ios/setup) and [email/password guide](https://firebase.google.com/docs/auth/ios/password-auth).

Registration/sign-in were confirmed working by the user. The user also confirmed receiving a password-reset email in Spam. An unsigned simulator build passed during integration. There is no automated test target currently configured.

### Face ID — simulator-only sign-in prototype

Simplified at the user's request on October 2, 2026. `Core/Services/SimulatorFaceIDService.swift` uses `#if targetEnvironment(simulator)` to enable LocalAuthentication and remember credentials only in Simulator. The app presents normal Face ID wording, but this is not the production biometric implementation. No Firebase collection, rule, or console provider change is needed.

How sign-in works:

1. A successful email/password sign-in or registration calls `remember(email:password:)`. The service keeps only the latest account's email/password pair in memory; another successful password sign-in replaces it.
2. The signed-in user enables Face ID in Settings. The service tracks enabled emails in memory, and an email is usable only if it matches the remembered credentials.
3. Sign-out clears the Firebase session and local tab-shell content, but intentionally retains the simulator credentials/enrollment for another sign-in during the same app run.
4. `authenticate(email:)` requires available Face ID, enabled enrollment, and matching remembered credentials before showing the biometric prompt. A successful simulated match returns the remembered password to the authentication view model.
5. `signInWithFaceID(email:)` submits the entered email and remembered password to Firebase. Only Firebase success updates the authenticated user/profile and opens Home. Network failures, changed passwords, or disabled accounts still prevent sign-in.

The user does not re-enter a password after the face matches. This is still Firebase email/password authentication behind the scenes, not a separate Firebase Face ID provider.

Test steps:

1. Run a Face ID iPhone simulator and choose Features → Face ID → Enrolled.
2. Sign in normally, open Profile → Settings, and turn on Face ID.
3. Sign out and enter the same email on Sign in. Tap Use Face ID.
4. Leave the password field empty and choose Features → Face ID → Matching Face. Firebase sign-in should complete and open Home without another password prompt. Non-matching Face must not initiate Firebase sign-in; cancellation is handled quietly.
5. Verify that network or invalid-credential failures stay on Sign in with an error rather than opening Home.
6. Turning Face ID off hides the button for that email but does not erase the in-memory credential pair. Restarting the app clears both credentials and enrollment. Firebase may independently restore its session after relaunch; sign out and sign in with a password before enabling Face ID again.
7. On physical devices, availability is always false, no password is remembered by this service, and biometric-assisted sign-in cannot run.

The former `FaceIDService` protected Keychain implementation and `FaceIDSetupView` password-confirmation sheet were removed, along with password-enrollment reauthentication and their extra state/error plumbing. No previous OS Keychain entries were read or deleted by this source-code cleanup; previously stored entries, if any, are not used by the prototype. These removed source files were not committed, so they cannot be restored through Git; production biometric login can be reimplemented later.

At the user's request, app-facing labels, permission text, and the biometric prompt use ordinary Face ID wording without simulator/demo labels: Settings shows Face ID, Sign in shows Use Face ID, and the prompt asks to verify identity for QuietSpot. The former success notice asking users to enter their password again has been removed.

This is a simulator testing prototype, not production-secure biometric login or an app lock. The password is retained as an ordinary in-memory string until replaced or the app terminates; it is not Keychain-protected. Nothing is saved to Firestore, app preferences, or disk by this service. Normal Firebase email/password authentication and session restoration remain available. Before device support or release, replace this with protected Keychain credentials or another valid Firebase authentication mechanism; never use a face match alone to fabricate a Firebase session.

Verification: simulator and unsigned generic iOS device builds passed after the latest biometric-assisted Firebase sign-in changes. Interactive matching/non-matching, cancellation, Firebase failure, and restart behavior still need runtime testing using the steps above; compile success is not proof that those flows have been exercised.

## Current café integration — metadata working, Base64 images awaiting verification

The user created a Firestore database in production mode, added a café document for Barista - Ward Place, and confirmed publishing the café read rules. Live metadata was confirmed working on October 1; the console configuration has not been independently inspected. The document ID may still be `glass-house`; the app displays its `name` field, not its ID. No particular document ID is hardcoded in the service.

```text
Firestore cafes → CafeService → CafeViewModel → MainTabView shared bindings
cafeImages/{cafeID}.imageBase64 → CafeImageService/cache → CafeImageViewModel → CafeImage
```

Every document returned from `cafes` must contain these exact case-sensitive fields:

| Field | Firestore type | Purpose |
| --- | --- | --- |
| `name` | String | Display name, currently Barista - Ward Place |
| `area` | String | Area shown on cards/details |
| `description` | String | Short café description |
| `location` | GeoPoint | Café latitude/longitude; not a nested map |

`@DocumentID` supplies the document ID during decoding; do not add a separate `id` field. Bundled-image names belong only to local preview data, not Firestore café metadata. Favorites and check-ins are separate future user/report records, not required metadata fields.

The user reports creating `cafeImages/{cafeID}` with a String field named `imageBase64`, publishing authenticated read-only image rules, and adding a single-field indexing exemption for `imageBase64`. The image document ID must exactly match its café's ID. Store raw Base64 text without a `data:image/...;base64,` prefix. Whitespace/newlines are removed before decoding; invalid data or missing documents show a retry placeholder rather than failing café metadata loading.

Resize/compress source JPEGs to approximately 100–200 KB for this prototype before encoding. Base64 adds roughly one-third to their size, and the entire image document must stay below Firestore's 1 MiB limit. The free tier has usage limits; this is not unlimited free image hosting. See [Firestore limits](https://firebase.google.com/docs/firestore/quotas) and [indexing best practices](https://firebase.google.com/docs/firestore/best-practices).

The user confirmed publishing this initial read-only rule set:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /cafes/{cafeID} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /cafeImages/{cafeID} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

This permits authenticated café/image reads and no client writes; unmatched collections remain inaccessible. Future collections need their own narrowly scoped rules. Do not make the database public to bypass a loading failure.

### Verification and troubleshooting

- The Firestore SDK, shared view model, navigation-ID migration, and Base64 image component compile in the simulator build. The user separately confirmed the existing app features and live Firebase café metadata reads working before the Base64 migration.
- The previously reported café-loading error is resolved. Its exact cause/fix was not supplied; no loading issue is currently outstanding.
- The Base64 image loader must be tested in the app: confirm Barista's photo in Home, Explore, details, and favorite thumbnails. Runtime photos come exclusively from Firestore; there is no URL-based fallback. Photo failures offer a retry button on café details, not nested inside tappable café cards. No remote records or hosted files were deleted during the local-code cleanup.
- `CafeService` fetches all café documents from the server and decodes them with `CafeDocument`. One missing or incorrectly typed required field in any document fails the whole load. It does not silently drop documents or fall back to sample cafés. See [Firebase Swift decoding](https://firebase.google.com/docs/firestore/solutions/swift-codable-data-mapping).
- If a future error indicates missing data or a type mismatch, inspect every café document against the field table above. If it indicates insufficient permissions, verify the deployed rules, signed-in session, and that the app's configuration points to the same Firebase project. Capture the complete error before selecting a fix for network/API configuration failures.
- Café metadata loads on tab-shell startup; pull-to-refresh on Home or Try again on the error banner repeats the server read. There is no realtime listener yet.
- Keep café image/details, GeoPoint map pins, empty check-in states, heart-to-favorite behavior across tabs, and preservation of local favorites/check-ins during refresh in regression checks. Sign-out/relaunch resets session-only content; favorites, check-ins, posts/likes, and profile photos are not yet remotely persisted.

### Cleanup audit

- Removed the unused `CafeDocument.coordinate` helper and its `CoreLocation` import. MapKit uses `CafeSnapshot.coordinate` instead.
- Removed the redundant `AppDelegate.swift` and its SwiftUI delegate adaptor on October 2. `ContentView.task` already starts the authentication view model, which configures Firebase before installing the auth listener; no second launch hook is needed for the current email/password authentication. The deleted file is tracked in Git and is recoverable from the last committed version.
- No other unused Swift files or asset sets were identified by the reference audit. Sample data and its five café images remain in use by SwiftUI previews; the runtime app does not use them as fallback data.
- Retained `CafeHero`, `BrandAccent`, and Xcode's configured `AccentColor`/`AppIcon` asset sets. No image assets were deleted.
- The former URL-based loader and model properties were removed during the Base64 migration. A follow-up reference audit found no remaining image-hosting code/dependency or unused Swift files/assets; obsolete migration references were removed from this guide.

## Remaining Firebase/backend structure — proposed additions

Add collections incrementally as each feature is connected. Firebase Auth accounts already exist independently of Firestore documents. Use Firestore for structured records and separate Base64 photo documents for this limited prototype. Use trusted backend operations where derived data must be protected. A dedicated image-storage provider remains an optional future scaling improvement.

```text
users/{userID}                         # Community-visible profile
  displayName, photoPath, createdAt, updatedAt
  favorites/{cafeID}
    createdAt
  private/settings                    # Owner-only document
    cafeUpdatesEnabled, mapRadiusKilometers

cafes/{cafeID}
  name, area, description
  location: GeoPoint, geohash
  latestStatus:
    noise, wifi, outlets, crowd, checkedAt, checkInID

cafeImages/{cafeID}                    # Implemented image-reading path
  imageBase64: String

checkIns/{checkInID}
  cafeID, authorID, noise, wifi, outlets, crowd, createdAt

posts/{postID}
  cafeID, authorID, text, createdAt, updatedAt, likeCount
  likes/{userID}
    createdAt
```

The basic café metadata and image fields above are already expected by the app. User records, geohashes, latest-status summaries, check-ins, posts, and likes shown here remain proposed additions, not connected backend features. Collection paths alternate between collections and documents; `private/settings` is a subcollection/document under a user.

### Data and query rules

- Café navigation and community café references now use stable Firestore string document IDs. Check-in and insight IDs remain local UUIDs until those features are persisted.
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

- Current café photos use Base64 strings in separate Firestore `cafeImages` documents, exempt from indexing, as an explicit small-prototype tradeoff. Do not embed them in the café metadata documents or automatically fetch all photos for Map. Profile photo uploads are not connected yet; select their provider and secure upload flow separately. Never bundle privileged backend/image-provider secrets in the app.
- Cloud Storage currently requires a Blaze billing account; eligible no-cost allowances vary by bucket/location. Do not promise universally free photo storage. See [Storage billing requirements](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024).
- When Firestore profiles are added, explicitly choose the source of truth and synchronization policy for display names; the current source is Firebase Auth. Changing this must preserve name updates on historical posts.
- Cache radius/settings locally and optionally synchronize account preferences. Appearance may remain device-specific. Biometric enrollment is managed by iOS, not Firebase.
- Nearby counts can be computed locally when location/data are available. A scheduled local notification cannot fetch fresh Firebase data when it fires. Future background café-update alerts need a deliberate backend/FCM/APNs design; do not rely on continuous Firestore listening while the app is suspended.
- Actual push delivery, token registration, background tasks, geofenced notifications, and notification deduplication are not implemented.

## Security and privacy requirements

- Never store passwords in Firestore or app preferences. The current simulator-only Face ID prototype deliberately retains the latest authenticated password in memory to reuse with Firebase after a face match; it does not write passwords to disk or access Keychain credentials. This is a temporary testing tradeoff, not production security. Physical-device biometric support requires a protected credential design before release.
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

Continue feature-by-feature: add the required Firebase product/service, implement its data layer and rules, replace sample data for that feature, and verify persistence and cross-account isolation. Keep the folder structure simple and update this document at the end of the coding session when requested to reflect what actually ships.

UI checks should include light/dark mode, large accessibility text, small iPhone layouts, readable image crops, navigation/back behavior, empty favorites/results/posts, permission-denied location/notifications, and network failures. Authentication checks should include session restoration, failed credentials, duplicate registration, reset email, name changes, and confirmed sign-out. A successful build alone is not evidence that every live backend flow works.
