import FirebaseCore
import Foundation

enum FirebaseConfiguration {
    static func configure() -> String? {
        if FirebaseApp.app() != nil { return nil }
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            return "Firebase setup is incomplete. Add GoogleService-Info.plist to the QuietSpot app target, then rebuild."
        }
        guard let options = FirebaseOptions(contentsOfFile: path),
              options.bundleID == Bundle.main.bundleIdentifier else {
            return "The Firebase configuration doesn’t match this app. Download the configuration for this target’s bundle ID."
        }
        FirebaseApp.configure(options: options)
        return nil
    }
}
