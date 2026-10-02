/// The app's authentication state, independent of Firebase SDK user types.
struct AuthenticationSession {
    let userID: String
    let email: String?
    let displayName: String?
}
