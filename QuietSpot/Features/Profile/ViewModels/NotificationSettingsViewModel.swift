import Observation
import UserNotifications

@MainActor
@Observable
final class NotificationSettingsViewModel {
    private(set) var authorization: UNAuthorizationStatus?
    private(set) var isRequesting = false
    private(set) var errorMessage: String?
    @ObservationIgnored private let service = NotificationService()

    var canReceiveNotifications: Bool {
        authorization == .authorized || authorization == .provisional || authorization == .ephemeral
    }

    var authorizationLabel: String {
        switch authorization {
        case .authorized: "Allowed"
        case .provisional: "Quiet delivery"
        case .ephemeral: "Temporarily allowed"
        case .denied: "Not allowed"
        case .notDetermined: "Not requested"
        case nil: "Checking…"
        @unknown default: "Unknown"
        }
    }

    func refreshPermission() async {
        authorization = await service.authorizationStatus()
    }

    func requestPermission() async {
        guard !isRequesting else { return }
        isRequesting = true
        errorMessage = nil
        defer { isRequesting = false }
        do {
            try await service.requestPermission()
            await refreshPermission()
        } catch {
            errorMessage = "Notification permission couldn’t be requested. Please try again."
        }
    }
}
