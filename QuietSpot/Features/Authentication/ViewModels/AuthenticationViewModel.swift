import FirebaseAuth
import Foundation
import Observation

@MainActor
@Observable
final class AuthenticationViewModel {
    private(set) var userID: String?
    private(set) var isRestoringSession = true
    private(set) var isBusy = false
    private(set) var isCreatingAccount = false
    private(set) var configurationError: String?
    var errorMessage: String?
    var profile = UserProfile()

    @ObservationIgnored private var listener: AuthStateDidChangeListenerHandle?
    @ObservationIgnored private var hasStarted = false

    deinit {
        if let listener { Auth.auth().removeStateDidChangeListener(listener) }
    }

    var canAuthenticate: Bool {
        hasStarted && configurationError == nil && !isRestoringSession && !isBusy
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        configurationError = FirebaseConfiguration.configure()
        guard configurationError == nil else {
            isRestoringSession = false
            return
        }
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                self?.updateSession(user)
                self?.isRestoringSession = false
            }
        }
    }

    func signIn(email: String, password: String) async {
        _ = await perform {
            let result = try await Auth.auth().signIn(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            updateSession(result.user)
        }
    }

    func createAccount(displayName: String, email: String, password: String) async {
        guard canAuthenticate else { return }
        isCreatingAccount = true
        defer { isCreatingAccount = false }
        _ = await perform {
            let result = try await Auth.auth().createUser(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            let request = result.user.createProfileChangeRequest()
            request.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            do {
                try await request.commitChanges()
            } catch {
                // Account creation succeeded even if the separate profile update failed.
                errorMessage = "Your account was created, but your display name couldn’t be saved. You can try again in Edit profile."
            }
            updateSession(result.user)
        }
    }

    func sendPasswordReset(email: String) async -> Bool {
        await perform {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                // Do not disclose whether an address belongs to an account.
                if AuthErrorCode(rawValue: (error as NSError).code) != .userNotFound { throw error }
            }
        }
    }

    func updateDisplayName(_ name: String) async -> Bool {
        guard userID != nil else {
            errorMessage = "Please sign in again before updating your profile."
            return false
        }
        return await perform {
            guard let user = Auth.auth().currentUser else { throw ProfileUpdateError.signedOut }
            let request = user.createProfileChangeRequest()
            request.displayName = name
            try await request.commitChanges()
            updateSession(user)
        }
    }

    func signOut() {
        guard configurationError == nil, !isBusy else { return }
        errorMessage = nil
        do {
            try Auth.auth().signOut()
            updateSession(nil)
        } catch {
            errorMessage = "Sign out couldn’t be completed. Please try again."
        }
    }

    private func updateSession(_ user: FirebaseAuth.User?) {
        userID = user?.uid
        if let user {
            let existingPhoto = profile.id == user.uid ? profile.photoData : nil
            profile = UserProfile(id: user.uid, displayName: user.displayName ?? "You", photoData: existingPhoto)
        } else {
            profile = UserProfile()
        }
    }

    private func perform(_ operation: () async throws -> Void) async -> Bool {
        guard canAuthenticate else { return false }
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        do {
            try await operation()
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    private static func message(for error: Error) -> String {
        switch AuthErrorCode(rawValue: (error as NSError).code) {
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

    private enum ProfileUpdateError: Error {
        case signedOut
    }
}
