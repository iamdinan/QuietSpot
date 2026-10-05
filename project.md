# QuietSpot project guide

Last reviewed: October 5, 2026. This document describes the current repository and distinguishes implemented behavior from proposed backend work. Update it at the end of a coding session when requested, rather than after every code change.

## App overview

QuietSpot is a SwiftUI café discovery and conditions-monitoring app. Users find cafés, save favorites, report conditions through check-ins, and share café insights with the community. Café metadata loads from Firestore; the first configured café is Barista - Ward Place in Colombo, Sri Lanka. Café photos use separate Firestore Base64 image documents for the limited prototype (around 20 photos). Metadata loading was confirmed working on October 1; the Base64 loader added October 2 still requires user verification.

The five tabs are always ordered **Home, Explore, Community, Map, Profile**. Firebase Authentication, café metadata/images, check-ins, profiles, favorites, and community posts/likes have Firestore-backed code. The user confirmed community posting works after the Share crash changes. The user confirmed on October 5 that the profile-photo saving issue is resolved. Local notifications for nearby favorite café stat changes are implemented; live banner delivery still needs manual verification.

### Current implementation status

| Capability | Current behavior |
| --- | --- |
| Registration, sign-in, sign-out | Firebase email/password Authentication |
| Session restoration | Firebase auth-state listener drives the app shell |
| Password reset | Firebase sends the reset email; user completes the reset through its link |
| Display name | Registration initially saves it to Firebase Auth; Firestore `users/{uid}.displayName` is the source of truth for subsequent profile edits and community authors |
| Profile photo | PhotosPicker → resized JPEG → Base64 → `users/{uid}.photoBase64`; saving issue confirmed resolved by the user on October 5 |
| Cafés and favorites | Firestore metadata and separate Base64 café image reads; per-user favorites use `users/{uid}/favorites/{cafeID}` |
| Check-ins | Firestore `cafes/{cafeID}/checkIns`; realtime latest-three listeners update shared café state |
| Community posts and likes | Firestore `communityPosts` and per-post `likes/{uid}`; stored count changes atomically with like/unlike; posting confirmed working, multi-account like tests still needed |
| Map | MapKit and Core Location with Firestore café coordinates and local radius filtering |
| Notifications | Local notifications for changed stats at favorite cafés within the map radius while the app is active; system permission and stored preference are respected |
| VoiceOver | Native iOS screen-reader support; live status and setup guidance in Settings → Accessibility; no app-owned toggle or speech engine |
| Face ID | Simulator-only biometric-assisted Firebase sign-in; reuses the latest successfully authenticated email/password held in memory after a matching face |
| Firestore | Metadata reads at tab startup and Home pull-to-refresh; simulator build passed and live loading confirmed working by the user |
| Storage, Cloud Functions, FCM | Not integrated into the app yet |

The authenticated shell resets its in-memory state on account changes and reloads that account's Firestore records. Cloud records are not deleted on sign-out. Local settings still use device-wide `AppStorage`, not account-specific cloud settings. There is no sample-data folder or runtime fallback to hardcoded cafés/posts.

## Technology and Xcode setup

- SwiftUI app in `QuietSpot.xcodeproj`; use the `QuietSpot` scheme.
- Current project deployment target: iOS 26.2. Xcode 26.2 was used for the verified simulator build. This is the current configuration, not a claim that every feature requires iOS 26.2.
- Bundle identifier: `dinan.QuietSpot` (case-sensitive).
- Apple frameworks: MapKit, CoreLocation, PhotosUI, ImageIO, UserNotifications, LocalAuthentication, and Observation/Combine.
- Firebase products linked: `FirebaseCore`, `FirebaseAuth`, and `FirebaseFirestore`.
- Metadata comes from `cafes`; Base64 café images come from `cafeImages` with matching document IDs. Check-ins, user profiles/favorites, and community posts/likes have dedicated Firestore services. There is no URL-based image loader or third-party image-hosting dependency.
- Firebase repository: `https://github.com/firebase/firebase-ios-sdk.git`.
- Swift Package Manager requirement: up to the next major version from `12.0.0`; current `Package.resolved` pins Firebase `12.19.2`.
- The app folder is an Xcode file-system-synchronized group. New Swift files inside it are normally included automatically.

An Xcode application using Swift Package Manager dependencies does **not** need to adopt a standalone package's `Sources/`, `Tests/`, and `Package.swift` layout.

## Folder structure

```text
QuietSpot/
├── project.md
├── Tests/                             # Standalone café notification policy regression checks
├── firestore-user-data.rules           # User/favorite rules fragment for console publishing
├── firestore-community.rules           # Community/like rules fragment for console publishing
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
    │   │                                  # CafeCheckInDocument, CafeInsightDocument,
    │   │                                  # CafeInsight, UserProfile, AuthenticationSession,
    │   │                                  # CafeStatUpdateTracker, CafeUpdateNotificationContext
    │   ├── Services/                      # FirebaseConfiguration, CafeService,
    │   │                                  # CafeImageService, CafeCheckInService,
    │   │                                  # AuthenticationService, UserDataService,
    │   │                                  # CommunityService, ProfilePhotoService,
    │   │                                  # NotificationService, CafeUpdateNotificationMonitor,
    │   │                                  # FaceIDService
    │   ├── ViewModels/                    # CafeViewModel, CafeImageViewModel
    │   ├── Location/LocationProvider.swift
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
    │   ├── Community/
    │   │   ├── Views/
    │   │   └── ViewModels/CommunityViewModel.swift
    │   ├── CafeDetails/
    │   │   ├── Views/                     # Details and check-in composer
    │   │   └── ViewModels/CafeCheckInViewModel.swift
    │   ├── Map/Views/
    │   └── Profile/
    │       ├── Views/                     # Profile, EditProfile, MyInsights,
    │       │                              # Settings, NotificationSettings, AccessibilitySettings
    │       └── ViewModels/                # EditProfileViewModel, NotificationSettingsViewModel
    └── Assets.xcassets/                   # Landing hero, app icon, adaptive colors; no café photos
```

### Organization rules

- `CafeDocument` decodes café metadata (`name`, `area`, `description`, `location`) and the Firestore document ID. `CafeService.fetchCafes()` performs a server read, sorted by name, with errors propagated. `CafeViewModel` maps documents to shared snapshots and owns one latest-three check-in listener per café. Refreshes preserve confirmed reports while reconnecting listeners; favorite flags derive from the authenticated user's Firestore favorite IDs.
- `CafeImageService` performs individual server reads of `cafeImages/{cafeID}`, decodes Base64 to `Data` and `UIImage`, and shares concurrent requests. Its app-process memory cache is limited to 20 images/20 MiB (eviction limits, not a guaranteed hard memory cap). `CafeImageViewModel` handles loading/errors; reusable `CafeImage` renders photos and retry placeholders. Map-only views do not fetch image documents. The cache is not disk-persistent and image changes require eviction/app restart to refetch a successfully cached photo.

- Keep screen-specific code inside its feature. Shared models, reusable UI, and cross-feature services belong in `Core`.
- Reuse `CafeStatusCard`, `CafeStatusGrid`, `CafePager`, `CafeInsightFeed`, and `ProfileAvatar` instead of duplicating them.
- Add view models when a feature gains asynchronous data loading, subscriptions, or substantial state/business logic. Do not create empty layers merely to match a template.
- The architecture is feature-based MVVM: services own SDK/framework operations; observable view models own asynchronous state; views render state and invoke actions. Authentication, café loading/images, check-in submission, community, profile editing, and notification permissions have view models. Pure presentation screens retain small local state/bindings rather than empty view-model layers.
- `AuthenticationService` returns `AuthenticationSession` instead of exposing Firebase user objects to views. `ProfilePhotoService` handles JPEG resizing; `NotificationService` handles system authorization, local notification delivery, and foreground presentation. `CafeUpdateNotificationMonitor` coordinates confirmed stat changes with favorites, radius, location, and app activity; the tracker/context models own duplicate suppression and eligibility. `UserDataService` owns profile/favorite operations; `CommunityService` owns posts/like transactions.
- Keep Firebase SDK calls outside presentation code where practical. Future Firestore services should feed feature view models rather than each row directly querying Firebase.

## UI and interaction requirements

Follow [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines). Native controls are a starting point, not proof of complete compliance: test layouts, interaction states, accessibility, and contrast on-device.

- Prefer native `TabView`, `NavigationStack`, `Form`, `List`, `Picker`, `Toggle`, searchable fields, and focused sheets.
- Support system/light/dark appearance with semantic backgrounds and adaptive colors.
- Use Dynamic Type text styles, readable wrapping, and approximately 44 × 44-point or larger interactive targets.
- Communicate status with text/icons as well as color. Give icon-only actions descriptive accessibility labels.
- Keep photos consistently cropped and bounded. Avoid unnecessarily large stat tiles or oversized decorative cards.
- Preserve drafts with discard confirmation where appropriate. Provide loading, empty, permission-denied, and error states.
- Validation remains focused: required auth fields, Firebase errors, nonblank insights up to 2,000 characters, display names of 1–100 characters, and a 700,000-byte limit for encoded profile photos. Firestore rule fragments constrain owners, fields, timestamps, and like-count transitions. Moderation, abuse controls, and comprehensive production validation remain future work.

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
- **Create account:** display name, email, password, and Create account. Firebase Auth creates the account/name; the user-data flow creates `users/{uid}` if missing without overwriting an existing profile.
- **Forgot password:** email field, reset button, loading/error feedback, and a neutral confirmation that does not reveal whether the address is registered.
- **Home:** exactly three sections: favorite café pulse (latest three favorites, all four stats, no pagination); all favorites (three per page); all cafés (three per page). The last two reuse the same café card style. Updating a favorite promotes it in the pulse ordering.
- **Explore:** café/area search and four positive filters: Quiet, Strong Wi‑Fi, Outlets free, Uncrowded. Active filters combine with AND logic. Café results paginate five per page.
- **Café details:** image, name/area, favorite heart, description, latest three check-ins, and Check in here. This one reusable screen opens for cafés from different tabs.
- **Check-in composer:** selects only allowed values and awaits Firestore acknowledgement before confirmation. Controls/dismissal are disabled during submission; failures keep the sheet open. Latest-three listeners refresh all tabs without a fake local check-in.
- **Community:** newest-first Firestore posts with loading/error/empty states and retry. The composer offers favorites only; whitespace-only or over-2,000-character text cannot be shared. It awaits server acknowledgement before dismissing and preserves the draft on error. No community pagination is implemented yet.
- **Post card:** café header/thumbnail/link, compact author/time line, insight text, and a separate like footer. Thumbs-up means like; hearts remain reserved for café favorites. Tap again to unlike through a Firestore transaction. Buttons disable while the user's like state loads or a change is pending. Likes do not change feed ordering.
- **Profile:** centered avatar/display name/Edit profile header; left-aligned My insights with count, Settings, and confirmed Sign out.
- **My insights:** filters posts by the current profile's user ID and reuses Community's cards/feed. Likes are shared between these screens. Post editing/deletion is not implemented.
- **Edit profile:** PhotosPicker, add/change/remove photo, edit display name, Save/Cancel, and draft-discard protection. Saves target Firestore, not Firebase Auth name updates. JPEGs are resized to at most 512 pixels and compressed at 0.85 quality, then encoded into `photoBase64`; removal writes an empty string. The user confirmed the photo-saving issue is resolved on October 5; the exact cause/fix was not supplied. Profile listeners resolve authors for old posts; current-user cards also use the shared profile state.
- **Settings:** appearance picker, Notifications, Accessibility, Face ID toggle, About QuietSpot. Simulator Face ID enrollment and the latest successfully authenticated email/password remain only in memory and reset when the app restarts. No password-confirmation sheet, Keychain storage, or disk persistence exists. A restored Firebase session without remembered credentials must sign out and sign in with a password before enabling Face ID. Map radius is controlled in Map, not Settings.
- **Accessibility:** live VoiceOver On/Off status from SwiftUI's `accessibilityVoiceOverEnabled` environment value, system setup instructions, basic gestures, slider guidance, and a link to Apple's VoiceOver guide. No Firebase integration or separate app preference is needed.
- **Map:** current location, proximity circle, and matching Firestore café pins. Radius is 1–10 km in 1 km steps, default 5 km. Without location, show a clearly labeled Colombo preview instead of pretending it is the user's location. Handle denied/approximate location. Map and café notifications share a `LocationProvider` owned by the signed-in tab shell; tracking can continue across tabs while the app is active and stops/clears its location when the app becomes inactive or the shell disappears.

`Core/SampleData` and its files were removed. List previews use empty state; café details/status previews use small inline examples. Preview photos use placeholders rather than querying Firestore. The runtime does not fall back to samples on error. Cafés without check-ins display “No check-ins yet”; missing conditions are not treated as positive filters. `CafeImage` shares cropping, loading, and unavailable placeholders across cards, thumbnails, and details.

### Native VoiceOver support and testing

QuietSpot follows the system VoiceOver setting automatically, including on authentication screens before sign-in. Enable it on an iPhone through Settings → Accessibility → VoiceOver, or ask Siri to turn it on. QuietSpot does not toggle the system screen reader, require enrollment, synthesize its own speech, or store a VoiceOver preference. See [Apple's VoiceOver HIG](https://developer.apple.com/design/human-interface-guidelines/voiceover) and [VoiceOver setup guide](https://support.apple.com/guide/iphone/iph3e2e415f/ios).

Implemented accessibility refinements:

- `Features/Profile/Views/AccessibilitySettingsView.swift` presents system status and help; `SettingsView` links to it under Preferences.
- Authentication fields have explicit labels; key screen titles and profile/café names expose heading traits for navigation.
- Home section headers combine their title, café count, and subtitle into a meaningful announcement. The pulse header is grouped, while individual café links remain separate.
- Shared café cards combine their content and hide redundant photo descriptions. Stat pills expose named noise, Wi-Fi, outlets, and crowd information rather than relying on color alone.
- `CafePager` accepts an accessibility context so favorites, all cafés, and Explore controls identify their section and page. Page changes post an `AccessibilityNotification.Announcement` only when VoiceOver is enabled. Explore's filter control reports the active-filter count.
- Favorite controls expose saved/selected state; like controls describe their action and use singular/plural counts. Native sliders retain adjustable behavior and report the map radius in kilometers with a descriptive hint.
- The landing photo and appearance button are separate accessibility elements. Café details keep photo retry controls reachable instead of hiding them inside a combined photo description.

For the project's Xcode 26.2 setup, Simulator testing uses Accessibility Inspector, not the complete iPhone VoiceOver speech/gesture experience:

1. Run QuietSpot in the iOS Simulator.
2. Choose Xcode → Open Developer Tool → Accessibility Inspector.
3. Select the running simulator in the Inspector's target dropdown.
4. Use the inspection pointer to inspect labels, values, and traits; use navigation controls to check element order.
5. Run the accessibility audit and review reported issues. Check authentication fields, Home/widget links and headings, café stats, favorites, community likes, pagination, Explore filters, and the map radius slider.

For actual VoiceOver speech and gestures, run on a physical iPhone, enable system VoiceOver, and verify QuietSpot's Accessibility status changes to On. Swipe left/right to navigate, double-tap to activate, use three-finger swipes to scroll, and swipe up/down on the selected radius slider to adjust it. Verify both On and Off status, meaningful announcements, reachable buttons, navigation/sheets, and page changes. Native VoiceOver support is separate from the currently simulator-only Face ID implementation. See [Apple's Accessibility Inspector guide](https://developer.apple.com/documentation/accessibility/accessibility-inspector) and [accessibility testing guidance](https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app).

Verification: the simulator build passed after these changes, and the diff whitespace check was clean. No Inspector audit or hands-on VoiceOver session has been performed by the coding agent; do not treat compilation as proof of accessibility compliance.

## Current authentication implementation

```text
QuietSpotApp → ContentView.task → AuthenticationViewModel.start()
                                          ↓
                              FirebaseConfiguration
                                          ↓
                              Configure Firebase SDK

Auth screen → AuthenticationViewModel → AuthenticationService → Firebase Authentication
                       ↓
                User ID / profile state
                       ↓
               ContentView → MainTabView
```

Key files and responsibilities:

- `App/QuietSpotApp.swift`: configures foreground local-notification presentation and opens the root `ContentView`; Firebase startup is handled once by the authentication view model's `start()` method.
- `Core/Services/FirebaseConfiguration.swift`: reads the bundled plist, checks bundle-ID compatibility, avoids duplicate configuration, and reports missing/mismatched setup without entering a fake authenticated session.
- `Core/Services/AuthenticationService.swift`: configures/observes Firebase Auth, performs sign-in/registration/reset/sign-out, maps sessions/errors, and saves the initial registration display name. The obsolete Auth display-name editing method was removed; edited names now belong to Firestore.
- `Features/Authentication/ViewModels/AuthenticationViewModel.swift`: `@MainActor`, `@Observable`; session state, auth actions, simulator Face ID, busy/errors, plus Firestore profile/favorite subscriptions via `UserDataService`. User-data readiness gates profile saves and favorite changes. Listeners reset on account changes and reject stale callbacks. Successful password sign-in/registration remembers simulator credentials; Face ID still requires Firebase acceptance.
- `Core/Services/FaceIDService.swift`: LocalAuthentication prompt, enabled-email set, and one in-memory email/password pair. Despite its general name, the current implementation remains simulator-only. Email matching trims whitespace and ignores case. It neither writes credentials to disk nor bypasses Firebase authentication.
- `App/ContentView.swift`: owns and injects authentication state, restores sessions, chooses authenticated/unauthenticated navigation, and presents account notices.
- `App/MainTabView.swift`: owns `CafeViewModel` and `CommunityViewModel`, injects shared community state, and receives the authenticated profile binding. It also owns the shared `LocationProvider` and `CafeUpdateNotificationMonitor`, starts subscriptions, syncs favorite flags and notification context, and presents café/account-data loading and retry feedback. The shell is keyed by user ID so accounts do not share local state.

`UserProfile.id` and post `authorID` use Firebase Authentication UID strings. Café, post, and persisted check-in IDs use Firestore document IDs. Never use a display name as an identifier. Community author listeners resolve names/photos from `users/{authorID}`, updating historical posts when profiles change.

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

Simplified at the user's request on October 2, 2026. The service was subsequently renamed to `Core/Services/FaceIDService.swift` (class `FaceIDService`); callers and the error domain (`FaceID`) were updated. This naming change did not enable physical-device support: `#if targetEnvironment(simulator)` still restricts LocalAuthentication and remembered credentials to Simulator. The app presents normal Face ID wording, but this is not the production biometric implementation. No Firebase collection, rule, or console provider change is needed.

How sign-in works:

1. A successful email/password sign-in or registration calls `remember(email:password:)`. The service keeps only the latest account's email/password pair in memory; another successful password sign-in replaces it.
2. The signed-in user enables Face ID in Settings. The service tracks enabled emails in memory, and an email is usable only if it matches the remembered credentials.
3. Sign-out clears the Firebase session and in-memory tab state, but retains simulator credentials/enrollment for another sign-in during the same app run. Firestore records remain saved and reload after sign-in.
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

The original protected Keychain implementation and `FaceIDSetupView` password-confirmation sheet were removed, along with password-enrollment reauthentication and their extra state/error plumbing. The current `FaceIDService.swift` reuses the original service name but contains the simplified in-memory prototype, not that removed implementation. No previous OS Keychain entries were read or deleted by this source-code cleanup; previously stored entries, if any, are not used by the prototype. The removed implementation was not committed at the time of cleanup, so it cannot be restored through Git; production biometric login can be reimplemented later.

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

`@DocumentID` supplies the document ID during decoding; do not add a separate `id` field. No bundled café-image-name field remains. Favorites and check-ins are separate implemented user/report records, not café metadata fields.

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

This is the historical initial rule set, not sufficient for current writes. Keep café/image metadata read-only, add nested check-in rules, and merge the user/community rule fragments described below. Do not replace deployed feature rules with this old example or make the database public to bypass an error. Deployed console rules have not been independently inspected.

### Verification and troubleshooting

- The Firestore SDK, shared view model, navigation-ID migration, and Base64 image component compile in the simulator build. The user separately confirmed the existing app features and live Firebase café metadata reads working before the Base64 migration.
- The previously reported café-loading error is resolved. Its exact cause/fix was not supplied; no loading issue is currently outstanding.
- The Base64 image loader must be tested in the app: confirm Barista's photo in Home, Explore, details, and favorite thumbnails. Runtime photos come exclusively from Firestore; there is no URL-based fallback. Photo failures offer a retry button on café details, not nested inside tappable café cards. No remote records or hosted files were deleted during the local-code cleanup.
- `CafeService` fetches all café documents from the server and decodes them with `CafeDocument`. One missing or incorrectly typed required field in any document fails the whole load. It does not silently drop documents or fall back to sample cafés. See [Firebase Swift decoding](https://firebase.google.com/docs/firestore/solutions/swift-codable-data-mapping).
- If a future error indicates missing data or a type mismatch, inspect every café document against the field table above. If it indicates insufficient permissions, verify the deployed rules, signed-in session, and that the app's configuration points to the same Firebase project. Capture the complete error before selecting a fix for network/API configuration failures.
- Café metadata still uses startup/refresh server reads, not a metadata listener. Check-in statuses, profiles, favorites, community posts, and individual like state use realtime listeners.
- Regression-check café photos, GeoPoint map pins, empty/error check-in states, favorite changes across tabs, and refresh preservation of confirmed reports. Verify persistence and account isolation after restart/sign-out. The user confirmed the profile-photo saving issue is resolved on October 5; the coding agent has not independently repeated the save/remove/relaunch checks.

### Cleanup audit

- Removed the unused `CafeDocument.coordinate` helper and its `CoreLocation` import. MapKit uses `CafeSnapshot.coordinate` instead.
- Removed the redundant `AppDelegate.swift` and its SwiftUI delegate adaptor on October 2. `ContentView.task` already starts the authentication view model, which configures Firebase before installing the auth listener; no second launch hook is needed for the current email/password authentication. The deleted file is tracked in Git and is recoverable from the last committed version.
- Deleted five obsolete bundled café image sets (`CafeGlassHouse`, `CafeCommonGrounds`, `CafeCoffeeStop`, `CafeKopiKade`, `CafeWhightCo`), about 12 MB of source images, and removed the bundled café image-name model/loader branch. Runtime café photos come exclusively from Firestore.
- Deleted `Core/SampleData/CafeSampleData.swift` and `CommunitySampleData.swift`, then removed the empty folder. Updated previews and removed synthetic check-in fallback generation. Committed versions of deleted files/assets remain recoverable from Git.
- Retained `CafeHero` for Landing, `BrandAccent`, and Xcode's configured `AccentColor`/`AppIcon` asset sets.
- The former URL-based loader and model properties were removed during the Base64 migration. A follow-up reference audit found no remaining image-hosting code/dependency or unused Swift files/assets; obsolete migration references were removed from this guide.

## Current Firestore data structure

These are the paths used by the current code, not proposed collection names. Firebase Auth accounts exist independently of Firestore documents. The app creates missing profile documents automatically; posting/checking in/favoriting creates the relevant records. Firebase console rule publishing remains a manual step.

```text
users/{userID}                         # Community-visible profile
  displayName: String
  photoBase64: String                  # Empty string means no photo; saving issue confirmed resolved by user
  createdAt: Timestamp
  updatedAt: Timestamp
  favorites/{cafeID}
    createdAt: Timestamp

cafes/{cafeID}
  name, area, description
  location: GeoPoint
  checkIns/{checkInID}
    authorID: String
    createdAt: Timestamp
    noiseLevel: String
    wifi: String
    outlets: String
    crowd: String

cafeImages/{cafeID}                    # Implemented image-reading path
  imageBase64: String

communityPosts/{postID}
  cafeID: String
  authorID: String
  text: String
  createdAt: Timestamp
  likeCount: Integer
  likes/{userID}
    createdAt: Timestamp
```

Do not use the older proposed top-level `posts` or `checkIns` paths. The code uses `communityPosts` and nested `cafes/{cafeID}/checkIns`. No `photoPath`, geohash, latest-status summary, cloud preference document, or post `updatedAt` field is currently implemented.

### Check-ins and café status

- `CafeCheckInViewModel` uses `CafeCheckInService.submit()` with the current Firebase UID and a server timestamp. Confirmation waits for server acknowledgement; offline queued writes are not presented as saved.
- The exact persisted values are `noiseLevel`: `Quiet`, `Moderate`, `Loud`; `wifi`: `Strong Wi‑Fi`, `Spotty Wi‑Fi`; `outlets`: `Outlets free`, `Outlets full`; `crowd`: `Uncrowded`, `Crowded`. Preserve capitalization and the Wi-Fi label's nonbreaking hyphen. The earlier proposed lowercase canonical codes are not the current schema.
- `CafeViewModel` observes each café's `checkIns`, descending `createdAt`, limit three. All tabs share these subscriptions. Pending-write snapshots are skipped; an empty cache is not treated as confirmed empty server history. Errors expose unavailable status rather than invented conditions.
- The newest report supplies the café's four displayed factors. Pulse order uses the server report date through the derived negative Unix-time `updateOrder`; this is a UI sorting value, not a Firestore field.
- Reading three reports does not delete older history. No aggregate latest-status document or backend function exists yet.
- Console rules must allow authenticated reads and narrowly scoped creates: existing café, `authorID == request.auth.uid`, exact allowed fields/status values, and `createdAt == request.time`. Clients must not modify/delete published reports. No deployable check-in rules file currently exists in the repository; inspect the actual deployed rules when troubleshooting.

### User profiles and favorites

- `UserDataService.createProfileIfNeeded()` uses a transaction to create only a missing `users/{uid}` document, seeded from the Auth display name or `You`, with an empty photo and server timestamps. Existing saved names/photos are not overwritten during sign-in.
- `AuthenticationViewModel` observes the profile and favorite subcollection, resets listeners/state on account changes, and guards stale callbacks with a generation token. Both must load before profile saving or heart changes are enabled. Failures appear in the account-data banner with retry.
- Firestore is the profile source of truth after initialization. Editing a name does not also change Firebase Auth's stored display name. Email/password remain in Authentication; they are not written to the public profile.
- Favorite documents use the café ID as their document ID. Heart changes await server acknowledgement, with duplicate taps disabled while saving. The shared café view model derives its flags from these IDs, updating Home, Explore, Map/details, and the community favorite picker consistently.
- The profile-photo saving issue was confirmed resolved by the user on October 5. The implemented path is: selection → `ProfilePhotoService` JPEG conversion → `saveProfile()` → `photoBase64`. Empty string removes a photo. Base64 strings above 700,000 bytes are rejected before writing; names/photos are written together with `updatedAt`.

### Community posts and likes

- `CommunityService` performs Firestore operations; `CommunityViewModel` owns shared posts, author-profile listeners, per-post current-user like listeners, loading/retry/errors, and pending-like state. Community and My insights use the same feed/cards and data.
- Posts are ordered by descending server `createdAt`. My insights filters the shared list by UID. The current listener loads all posts; there is no five-post pagination or server-side author query yet.
- The post stores only the author UID, not a copied display name/photo. One profile listener per distinct author resolves current names/photos and refreshes old posts. No automatic Firestore join is assumed.
- `setLiked()` reads the post/count and `likes/{uid}` in a transaction. Adding/removing the like changes `likeCount` by exactly +1/−1; repeating the same desired state is a no-op. Counts cannot become negative through this flow. Concurrent transactions retry through Firestore. See [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions).
- The community rules fragment permits signed-in reads, restricts posting to the author's UID and a currently favorited café, validates text/fields/timestamp/initial zero count, and denies post editing/deletion. Like records are owner-only; a count update must match an actual same-user like transition, validated with `existsAfter()`/`getAfter()`. Publishing these rules is required for enforcement.
- Sharing waits for the server before dismissing; errors retain the draft. Likes/counts come from confirmed listener updates rather than optimistic local counters.

### Rules publishing and indexes

- `firestore-user-data.rules` and `firestore-community.rules` are **fragments**, not complete standalone rule files. Back up the console rules, paste each block inside the existing `/databases/{database}/documents` scope, preserve existing café/image/check-in blocks, and Publish. The coding agent cannot inspect/publish the Firebase console; the current deployed rule set has not been independently verified.
- User profiles contain community-visible fields and allow signed-in reads; only their owner can create/update them. Favorites are private to their owner and must reference an existing café. Profile deletion is disabled.
- Retain the reported indexing exemption for `cafeImages.imageBase64`. Add an exemption for `users.photoBase64` because it is not queried. Do not disable the `createdAt` index needed by check-in/post ordering. Confirm index settings manually; code does not configure them.
- Do not loosen rules globally to work around permission errors. Capture the actual error and check the project, signed-in UID, document types, rule nesting, and required indexes.

### Verification and known issues — October 5, 2026

- Simulator builds passed after architecture cleanup, sample/asset deletion, user/favorite integration, community integration, and the latest Share-flow changes. Build success does not verify deployed rules or live persistence.
- **Community posting confirmed working by the user after the crash changes.** Previously, tapping Share crashed with `EXC_BAD_ACCESS` in `swift_retain` while `CommunityService.share()` built the write dictionary. The form now captures the café ID/text/view model before starting its MainActor task, calls the view model directly instead of an intermediate async callback, and uses a reference-type `CommunityService` with an explicit write payload. The exact low-level lifetime cause was not independently proven; the user confirmed the resulting posting flow works.
- **Profile-photo saving issue resolved**, confirmed by the user on October 5. Photos are stored in `users/{uid}.photoBase64`. The exact cause/fix was not supplied; this records the user’s confirmation rather than an independent runtime test by the coding agent.
- Still verify likes with two accounts (one like per UID, unlike, simultaneous changes, persistence after restart), favorite account isolation, profile-name changes on another user's historical posts, and check-in propagation. Those specific runtime checks have not been independently performed by the coding agent.
- No Xcode automated test target or Firestore emulator rule tests currently exist. Standalone notification policy checks are available in `Tests/` and run with `sh Tests/run-cafe-notification-tests.sh`; they passed on October 5. Console publishing and live device/simulator interaction remain manual steps.

## Local café stat notifications

Implemented October 5, 2026 using UserNotifications and the existing Firestore check-in listeners. Alerts cover noise, Wi-Fi, outlets, and crowd changes at favorite cafés within the selected map radius while QuietSpot is active, across all signed-in tabs.

- `CafeCheckInService.observeLatest()` supplies a separate confirmed-change callback only for server snapshots without pending writes. Cached reports can still populate café screens without triggering notification processing.
- `CafeViewModel.onConfirmedStatusChange` forwards the café and newest confirmed report to `CafeUpdateNotificationMonitor`; no extra Firestore subscriptions are created for notifications.
- `CafeStatUpdateTracker` establishes a silent baseline from the first confirmed snapshot for each café. Subsequent reports must have a different ID and a newer timestamp, with at least one changed stat. Repeated snapshots, older reports, empty snapshots, and new reports with identical stats do not alert. A first report after a confirmed empty history can alert. Baselines advance even when a café is ineligible, so changing favorites, location, radius, or preferences does not replay an old update.
- `CafeUpdateNotificationContext` requires a signed-in user, a favorite café, valid location accuracy, an enabled preference, and an exact distance within `mapRadiusKilometers`. `MainTabView` additionally requires loaded profile/favorite data and an active scene. The shared radius defaults to 5 km and uses the Map control’s 1–10 km range.
- `MainTabView` shares location with Map, updates notification context as favorites/location/radius/preferences change, and cancels pending delivery tasks when context changes or the shell disappears. The monitor resets baselines when its user ID changes. Location startup outside Map does not prompt for permission; Map requests when-in-use access. Tracking rejects cached fixes older than five minutes when received and clears location when stopped.
- `NotificationService` checks current iOS notification authorization before adding an immediate local request. The title contains the café name and “Stats updated”; the body lists all four stats. Request identifiers include user, café, and report IDs; `userInfo` includes the café ID. `QuietSpotApp` installs a retained notification-center delegate requesting foreground banner, notification-list, and sound presentation. Notification-tap navigation is not implemented.
- Enable delivery through **Profile → Settings → Notifications → Allow notifications**, keep **Café updates** enabled, and allow location through **Map**. Denied notification permission, unavailable location, disabled updates, and cafés outside the radius prevent delivery. The notification preference and radius remain device-wide `AppStorage` settings.
- This feature detects updates while the app is active. It does not fetch or monitor fresh stats while suspended or closed. Duplicate tracking is in memory; a new signed-in shell establishes fresh silent baselines.

Verification on October 5: the unsigned Debug simulator build passed, `git diff --check` was clean, and `sh Tests/run-cafe-notification-tests.sh` passed. The standalone checks cover initial/repeated/older reports, changed versus identical stats, empty history, favorites, sign-in state, enabled preferences, missing location, and radius filtering. Live Firestore-to-banner delivery has not been independently verified by the coding agent.

Manual verification:

1. Run QuietSpot in Simulator, sign in, allow notifications, and enable Café updates.
2. Set a simulator location near a real loaded café, open Map to allow location access, and choose a radius that includes the café.
3. Favorite the café and wait for its current confirmed stats to load.
4. Submit a new check-in with at least one different stat, from this app or another signed-in device. Keep the receiving app active; verify a local banner with the café name and four stats, including while viewing another tab.
5. Confirm initial loads and identical-stat reports stay silent. Repeat with the café unfavorited, outside a smaller radius, updates disabled, and permissions denied; verify no alerts. Restore eligibility and confirm old updates are not replayed.

## Remaining backend work

- Add cursor-based server pagination before the community dataset grows. The current all-post listener plus per-post like/profile listeners suits the small prototype, not an unbounded feed. See [Firestore pagination](https://firebase.google.com/docs/firestore/query-data/query-cursors).
- Consider a trusted latest-status summary for cafés to reduce per-café report listeners at scale. Any summary updater should be retry-safe and reject older reports overwriting newer status.
- Map radius/search still operate locally over loaded cafés. Larger-area searches need a deliberate indexed/geoquery strategy, exact-distance filtering, and deduplication; geohashes are not currently stored. See [Firebase geoqueries](https://firebase.google.com/docs/firestore/solutions/geoqueries).
- Café Base64 photos remain a deliberate small-prototype tradeoff. Profile photos use the same encoding approach; their saving issue was confirmed resolved by the user on October 5. A dedicated image provider can be considered later; there is no Cloud Storage integration now. Never bundle privileged provider secrets.
- Appearance, notification preference, and map radius remain local/device-wide. Cloud preferences and account-specific settings are not implemented. Biometric enrollment remains separate from Firestore.
- Local café stat notifications and in-memory duplicate suppression are implemented for active app use. Push tokens, FCM/APNs delivery, background jobs, and geofenced notifications remain unimplemented. This implementation does not monitor fresh café stats while the app is closed; no backend notification service is required for the current local feature.
- Plan moderation/reporting, account deletion with related-data cleanup, abuse protection, and production biometric credential storage before release.

## Security and privacy requirements

- Never store passwords in Firestore or app preferences. The current simulator-only Face ID prototype deliberately retains the latest authenticated password in memory to reuse with Firebase after a face match; it does not write passwords to disk or access Keychain credentials. This is a temporary testing tradeoff, not production security. Physical-device biometric support requires a protected credential design before release.
- Keep email and private settings out of community-visible profile documents. Only authenticated owners may change their profile/favorites/like records. Current posts cannot be edited/deleted by clients; users may only change the count through the guarded like transaction.
- Deploy deny-by-default Firestore rules with explicit permitted reads/writes and field/type/status validation. Café metadata/images remain client read-only; aggregate like counts may change only with the same user's validated like record transition, not an arbitrary client update.
- The community rule fragment checks that `authorID` is the authenticated user and the café is favorited at creation time. Removing a favorite later does not delete historical posts.
- Plan moderation/reporting, account deletion, and related-data cleanup before a public launch. Deleting a Firestore parent document does not automatically delete its subcollections. See [Firestore data model](https://firebase.google.com/docs/firestore/data-model).
- Firebase client configuration identifies the project; a Firebase-only API key is not an administrator credential. Still review API restrictions, quotas, and usage. Never reuse it for unrelated paid APIs, particularly Gemini. See [Firebase API-key guidance](https://firebase.google.com/docs/projects/api-keys).
- A GitHub key warning is a prompt to inspect restrictions and usage, not proof of compromise. If the key grants inappropriate access or is misused, replace/restrict it, update local configuration, and test before retiring the old key.
- Excluding the plist from a public repository is an optional project-sharing policy; this document does not change `.gitignore` or Git history. Exclusion does not revoke a key or remove previously committed copies.
- Never commit service-account JSON credentials, private signing/APNs keys, passwords, or privileged backend tokens. Do not paste actual configuration values into this documentation.
- Consider App Check for supported services and abuse/rate controls as backend integration progresses. Security must not depend on hiding values bundled in an iOS app.

## Development handoff

Next priority: manually verify local café notification delivery, then verify persistence, multi-account likes/favorites, author updates, and check-in propagation. The profile-photo saving issue is resolved according to the user. Continue feature-by-feature with services/view models and narrowly scoped rules. Keep the folder structure simple and update this document at the end of a coding session when requested.

UI checks should include light/dark mode, large accessibility text, small iPhone layouts, readable image crops, navigation/back behavior, empty favorites/results/posts, permission-denied location/notifications, and network failures. Use Accessibility Inspector in Simulator and test native VoiceOver speech, gestures, headings, control states, and pagination on a physical iPhone. Authentication checks should include session restoration, failed credentials, duplicate registration, reset email, name changes, and confirmed sign-out. A successful build alone is not evidence that every live backend flow or accessibility interaction works.
