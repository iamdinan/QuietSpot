import FirebaseAuth
import Foundation
import Testing
@testable import QuietSpot

@Suite("Authentication error guidance")
@MainActor
struct AuthenticationMessageTests {
    @Test("Invalid credentials do not reveal whether an account exists",
          arguments: [AuthErrorCode.wrongPassword, .userNotFound, .invalidCredential])
    func credentialPrivacy(code: AuthErrorCode) {
        let error = NSError(domain: "FIRAuthErrorDomain", code: code.rawValue)
        #expect(AuthenticationService.message(for: error) == "The email or password is incorrect. Please try again.")
    }

    @Test("Recoverable failures give relevant guidance", arguments: [
        (AuthErrorCode.invalidEmail, "valid email"), (.emailAlreadyInUse, "already uses"),
        (.weakPassword, "stronger password"), (.networkError, "internet connection"),
        (.tooManyRequests, "wait"), (.userDisabled, "disabled"),
        (.requiresRecentLogin, "sign out and sign in"), (.invalidAPIKey, "Firebase configuration")
    ])
    func recoveryGuidance(code: AuthErrorCode, phrase: String) {
        #expect(AuthenticationService.message(for: NSError(domain: "FIRAuthErrorDomain", code: code.rawValue)).contains(phrase))
    }

    @Test("Unknown errors use a safe fallback")
    func unknownError() {
        #expect(AuthenticationService.message(for: NSError(domain: "unexpected", code: -1)).contains("try again"))
    }

    @Test("The test scheme launches an isolated host instead of the normal signed-in shell")
    func isolatedHost() {
        #expect(ProcessInfo.processInfo.environment["QUIETSPOT_UNIT_TESTS"] == "1")
    }
}
