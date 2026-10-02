import LocalAuthentication
import Foundation
import Observation

@MainActor
@Observable
final class AuthenticationViewModel {
    private(set) var userID: String?
    private(set) var email: String?
    private(set) var faceIDEnabled = false
    private(set) var faceIDAvailable = false
    private(set) var faceIDMessage = "Checking Face ID…"
    private(set) var isRestoringSession = true
    private(set) var isBusy = false
    private(set) var isCreatingAccount = false
    private(set) var configurationError: String?
    var errorMessage: String?
    var profile = UserProfile()

    @ObservationIgnored private let service = AuthenticationService()
    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private let faceID = FaceIDService()

    var canAuthenticate: Bool {
        hasStarted && configurationError == nil && !isRestoringSession && !isBusy
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        configurationError = service.start { [weak self] session in
            guard let self else { return }
            self.updateSession(session)
            self.isRestoringSession = false
        }
        if configurationError != nil { isRestoringSession = false }
    }

    func signIn(email: String, password: String) async {
        _ = await perform {
            let session = try await service.signIn(email: email, password: password)
            faceID.remember(email: session.email ?? email, password: password)
            updateSession(session)
        }
    }

    func refreshFaceID() {
        let needsPasswordSignIn = email.map { !faceID.hasCredentials(email: $0) } ?? false
        faceIDAvailable = faceID.available && !needsPasswordSignIn
        if !faceID.available {
            faceIDMessage = "Face ID is unavailable. Check that Face ID is set up on your device."
        } else if needsPasswordSignIn {
            faceIDMessage = "Sign out and sign in with your password before enabling Face ID."
        } else {
            faceIDMessage = "Sign in with Face ID instead of entering your password."
        }
        faceIDEnabled = email.map { faceID.isEnabled(email: $0) } ?? false
    }

    func hasFaceID(email: String) -> Bool {
        faceID.isEnabled(email: email)
    }

    func setFaceIDEnabled(_ enabled: Bool) {
        guard let email, !isBusy else { return }
        faceID.setEnabled(enabled, email: email)
        refreshFaceID()
    }

    func signInWithFaceID(email: String) async {
        _ = await perform {
            guard let password = try await faceID.authenticate(email: email) else { return }
            let session = try await service.signIn(email: email, password: password)
            updateSession(session)
        }
    }

    func createAccount(displayName: String, email: String, password: String) async {
        guard canAuthenticate else { return }
        isCreatingAccount = true
        defer { isCreatingAccount = false }
        _ = await perform {
            let result = try await service.createAccount(displayName: displayName, email: email, password: password)
            faceID.remember(email: result.session.email ?? email, password: password)
            if !result.profileSaved {
                errorMessage = "Your account was created, but your display name couldn’t be saved. You can try again in Edit profile."
            }
            updateSession(result.session)
        }
    }

    func sendPasswordReset(email: String) async -> Bool {
        await perform {
            try await service.sendPasswordReset(email: email)
        }
    }

    func updateDisplayName(_ name: String) async -> Bool {
        guard userID != nil else {
            errorMessage = "Please sign in again before updating your profile."
            return false
        }
        return await perform {
            let session = try await service.updateDisplayName(name)
            updateSession(session)
        }
    }

    func signOut() {
        guard configurationError == nil, !isBusy else { return }
        errorMessage = nil
        do {
            try service.signOut()
            updateSession(nil)
        } catch {
            errorMessage = "Sign out couldn’t be completed. Please try again."
        }
    }

    private func updateSession(_ user: AuthenticationSession?) {
        userID = user?.userID
        email = user?.email
        refreshFaceID()
        if let user {
            let existingPhoto = profile.id == user.userID ? profile.photoData : nil
            profile = UserProfile(id: user.userID, displayName: user.displayName ?? "You", photoData: existingPhoto)
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
        } catch let error as LAError where [.userCancel, .appCancel, .systemCancel].contains(error.code) {
            return false
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    private static func message(for error: Error) -> String {
        if error is LAError || (error as NSError).domain == "FaceID" {
            return error.localizedDescription
        }
        return AuthenticationService.message(for: error)
    }
}
