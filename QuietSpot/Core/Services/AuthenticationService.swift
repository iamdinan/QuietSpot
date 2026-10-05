import FirebaseAuth
import Foundation

@MainActor
final class AuthenticationService {
    private var listener: AuthStateDidChangeListenerHandle?

    deinit {
        if let listener { Auth.auth().removeStateDidChangeListener(listener) }
    }

    func start(onChange: @escaping (AuthenticationSession?) -> Void) -> String? {
        if let error = FirebaseConfiguration.configure() { return error }
        guard listener == nil else { return nil }
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                onChange(Auth.auth().currentUser.map(self.session))
            }
        }
        return nil
    }

    func signIn(email: String, password: String) async throws -> AuthenticationSession {
        let result = try await Auth.auth().signIn(withEmail: normalizedEmail(email), password: password)
        return session(result.user)
    }

    func createAccount(displayName: String, email: String, password: String) async throws -> (session: AuthenticationSession, profileSaved: Bool) {
        let result = try await Auth.auth().createUser(withEmail: normalizedEmail(email), password: password)
        let request = result.user.createProfileChangeRequest()
        request.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await request.commitChanges()
            return (session(result.user), true)
        } catch {
            // Account creation succeeded even if the separate name update failed.
            return (session(result.user), false)
        }
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: normalizedEmail(email))
        } catch {
            // Do not disclose whether an address belongs to an account.
            if AuthErrorCode(rawValue: (error as NSError).code) != .userNotFound { throw error }
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    static func message(for error: Error) -> String {
        return switch AuthErrorCode(rawValue: (error as NSError).code) {
        case .invalidEmail: "Enter a valid email address."
        case .wrongPassword, .userNotFound, .invalidCredential: "The email or password is incorrect. Please try again."
        case .emailAlreadyInUse: "An account already uses this email. Sign in or reset your password."
        case .weakPassword: "This password doesn’t meet the account’s password requirements. Please choose a stronger password."
        case .networkError: "Check your internet connection and try again."
        case .tooManyRequests: "Too many attempts. Please wait a little before trying again."
        case .userDisabled: "This account is disabled. Please contact support."
        case .operationNotAllowed: "Email/password sign-in is not enabled. Enable it in the Firebase console."
        case .invalidAPIKey, .appNotAuthorized: "Check the Firebase configuration and registered iOS bundle ID."
        case .requiresRecentLogin: "Please sign out and sign in again, then retry."
        default: "The request couldn’t be completed. Please try again."
        }
    }

    private func session(_ user: FirebaseAuth.User) -> AuthenticationSession {
        AuthenticationSession(userID: user.uid, email: user.email, displayName: user.displayName)
    }

    private func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

}
