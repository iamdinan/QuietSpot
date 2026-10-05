import OSLog
import UserNotifications

@MainActor
struct NotificationService {
    /// Keep a strong reference: the notification center holds its delegate weakly.
    private static let presentationDelegate = CafeNotificationDelegate()

    func configurePresentation() {
        UNUserNotificationCenter.current().delegate = Self.presentationDelegate
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestPermission() async throws {
        _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func sendCafeUpdate(cafe: CafeSnapshot, report: CafeCheckIn, userID: String) async throws {
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            Logger(subsystem: "dinan.QuietSpot", category: "CafeNotifications")
                .notice("Café alert skipped: notification permission status \(status.rawValue)")
            return
        }
        try Task.checkCancellation()
        let content = UNMutableNotificationContent()
        content.title = "New check-in at \(cafe.name)"
        let noise = switch report.noiseLevel {
        case .quiet: "quiet"
        case .moderate: "moderately noisy"
        case .loud: "loud"
        }
        let wifi = report.wifi == "Strong Wi‑Fi" ? "strong" : "spotty"
        let outlets = report.outlets == "Outlets free" ? "outlets are available" : "all outlets are in use"
        content.body = "It’s \(noise) and \(report.crowd.lowercased()). Wi-Fi is \(wifi), and \(outlets)."
        content.sound = .default
        content.userInfo = ["cafeID": cafe.id]
        let request = UNNotificationRequest(
            identifier: "cafe-update.\(userID).\(cafe.id).\(report.id)",
            content: content, trigger: nil
        )
        try await UNUserNotificationCenter.current().add(request)
    }
}

private final class CafeNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
