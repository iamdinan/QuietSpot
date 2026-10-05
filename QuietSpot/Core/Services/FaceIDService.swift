import Foundation
import LocalAuthentication

/// Face ID sign-in support with temporary, in-memory credentials.
/// Device support requires protected credential storage before release.
@MainActor
final class FaceIDService {
    private var enabledEmails = Set<String>()
    private var credentials: (email: String, password: String)?

    func remember(email: String, password: String) {
        #if targetEnvironment(simulator)
        credentials = (normalized(email), password)
        #endif
    }

    func hasCredentials(email: String) -> Bool {
        credentials?.email == normalized(email)
    }

    var available: Bool {
        #if targetEnvironment(simulator)
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            && context.biometryType == .faceID
        #else
        return false
        #endif
    }

    func isEnabled(email: String) -> Bool {
        enabledEmails.contains(normalized(email)) && hasCredentials(email: email)
    }

    func setEnabled(_ enabled: Bool, email: String) {
        let email = normalized(email)
        guard !email.isEmpty else { return }
        if enabled && available && hasCredentials(email: email) { enabledEmails.insert(email) }
        else { enabledEmails.remove(email) }
    }

    func authenticate(email: String) async throws -> String? {
        #if targetEnvironment(simulator)
        guard available, isEnabled(email: email), let credentials else {
            throw NSError(domain: "FaceID", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Face ID is unavailable or not enabled for this account. Check your Face ID settings."
            ])
        }
        let context = LAContext()
        context.localizedFallbackTitle = ""
        defer { context.invalidate() }
        let matched = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Verify your identity for QuietSpot."
        )
        return matched ? credentials.password : nil
        #else
        return nil
        #endif
    }

    private func normalized(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
