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
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }
        try Task.checkCancellation()
        let content = UNMutableNotificationContent()
        content.title = "\(cafe.name) · Stats updated"
        content.body = "Noise: \(report.noiseLevel.rawValue) · Wi-Fi: \(report.wifi) · Outlets: \(report.outlets) · Crowd: \(report.crowd)"
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
