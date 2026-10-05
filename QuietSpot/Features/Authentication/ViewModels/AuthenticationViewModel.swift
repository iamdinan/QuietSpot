import LocalAuthentication
import Foundation
import Observation
import FirebaseFirestore

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
    private(set) var favoriteCafeIDs: Set<String> = []
    private(set) var isUserDataReady = false
    private(set) var savingFavoriteIDs: Set<String> = []
    private(set) var userDataError: String?

    @ObservationIgnored private let service = AuthenticationService()
    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private let faceID = FaceIDService()
    @ObservationIgnored private let userData = UserDataService()
    @ObservationIgnored private var userDataTask: Task<Void, Never>?
    @ObservationIgnored private var profileListener: ListenerRegistration?
    @ObservationIgnored private var favoritesListener: ListenerRegistration?
    @ObservationIgnored private var userDataGeneration = UUID()
    @ObservationIgnored private var hasLoadedProfile = false
    @ObservationIgnored private var hasLoadedFavorites = false

    deinit {
        userDataTask?.cancel()
        profileListener?.remove()
        favoritesListener?.remove()
    }

    var canAuthenticate: Bool {
        hasStarted && configurationError == nil && !isRestoringSession && !isBusy
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        configurationError = service.start { [weak self] session in
            guard let self else { return }
            guard !self.isCreatingAccount else { return }
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

    func saveProfile(displayName: String, photoData: Data?) async -> Bool {
        guard let userID, isUserDataReady else {
            errorMessage = "Please sign in again before updating your profile."
            return false
        }
        return await perform {
            try await userData.saveProfile(userID: userID, displayName: displayName, photoData: photoData)
            guard self.userID == userID else { return }
            profile = UserProfile(id: userID, displayName: displayName, photoData: photoData)
        }
    }

    func setFavorite(cafeID: String, enabled: Bool) async {
        guard let userID, isUserDataReady, !savingFavoriteIDs.contains(cafeID) else { return }
        let generation = userDataGeneration
        savingFavoriteIDs.insert(cafeID)
        defer { if generation == userDataGeneration { savingFavoriteIDs.remove(cafeID) } }
        do {
            try await userData.setFavorite(userID: userID, cafeID: cafeID, enabled: enabled)
            guard generation == userDataGeneration else { return }
            if enabled { favoriteCafeIDs.insert(cafeID) } else { favoriteCafeIDs.remove(cafeID) }
        } catch {
            guard generation == userDataGeneration else { return }
            errorMessage = "Couldn’t save your favourite. \(error.localizedDescription)"
        }
    }

    func retryUserData() {
        guard let userID else { return }
        observeUserData(userID: userID, defaultName: profile.displayName)
    }

    private func observeUserData(userID: String, defaultName: String) {
        userDataTask?.cancel()
        profileListener?.remove()
        favoritesListener?.remove()
        userDataGeneration = UUID()
        let generation = userDataGeneration
        isUserDataReady = false
        hasLoadedProfile = false
        hasLoadedFavorites = false
        userDataError = nil
        profileListener = userData.observeProfile(userID: userID) { [weak self] result in
            guard let self, generation == self.userDataGeneration else { return }
            switch result {
            case .success(let profile):
                self.profile = profile
                self.hasLoadedProfile = true
                self.isUserDataReady = self.hasLoadedFavorites
                if self.isUserDataReady { self.userDataError = nil }
            case .failure(let error):
                self.hasLoadedProfile = false
                self.isUserDataReady = false
                self.userDataError = "Couldn’t load your profile. \(error.localizedDescription)"
            }
        }
        favoritesListener = userData.observeFavorites(userID: userID) { [weak self] result in
            guard let self, generation == self.userDataGeneration else { return }
            switch result {
            case .success(let ids):
                self.favoriteCafeIDs = ids
                self.hasLoadedFavorites = true
                self.isUserDataReady = self.hasLoadedProfile
                if self.isUserDataReady { self.userDataError = nil }
            case .failure(let error):
                self.isUserDataReady = false
                self.hasLoadedFavorites = false
                self.userDataError = "Couldn’t load your favourites. \(error.localizedDescription)"
            }
        }
        // Transactions require a server. Cached profile/favourites remain usable if this fails.
        userDataTask = Task { [weak self] in
            guard let self, !NetworkStatus.shared.isOffline else { return }
            do {
                try await userData.createProfileIfNeeded(userID: userID, displayName: defaultName)
            } catch {
                guard !Task.isCancelled, generation == userDataGeneration, !hasLoadedProfile else { return }
                userDataError = "Couldn’t prepare your profile. \(error.localizedDescription)"
            }
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
        let previousUserID = userID
        userID = user?.userID
        if previousUserID != userID || userID == nil {
            // Clear the previous account's widget and Siri data before loading another account.
            PulseWidgetPublisher.publish(PulseWidgetContent(state: userID == nil ? .signedOut : .loading))
            CommunityPostSiriSnapshot(state: userID == nil ? .signedOut : .loading).save()
        }
        email = user?.email
        refreshFaceID()
        if let user {
            if previousUserID != user.userID {
                profile = UserProfile(id: user.userID, displayName: user.displayName ?? "You")
                favoriteCafeIDs = []
                savingFavoriteIDs = []
                observeUserData(userID: user.userID, defaultName: profile.displayName)
            }
        } else {
            userDataTask?.cancel()
            profileListener?.remove()
            favoritesListener?.remove()
            userDataGeneration = UUID()
            favoriteCafeIDs = []
            savingFavoriteIDs = []
            isUserDataReady = false
            userDataError = nil
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
        if (error as NSError).domain == "UserData" || (error as NSError).domain == FirestoreErrorDomain {
            return "Couldn’t save your profile. \(error.localizedDescription)"
        }
        if error is LAError || (error as NSError).domain == "FaceID" {
            return error.localizedDescription
        }
        return AuthenticationService.message(for: error)
    }
}
