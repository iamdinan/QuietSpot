import CoreLocation
import OSLog

@MainActor
final class CafeUpdateNotificationMonitor {
    private var tracker = CafeStatUpdateTracker()
    private var context = CafeUpdateNotificationContext()
    private var deliveryTasks: [UUID: Task<Void, Never>] = [:]
    private let service = NotificationService()
    private let logger = Logger(subsystem: "dinan.QuietSpot", category: "CafeNotifications")

    func updateContext(
        userID: String?, favoriteIDs: Set<String>, location: CLLocation?,
        radiusKilometers: Double, enabled: Bool
    ) {
        cancelDelivery()
        if context.userID != userID { tracker = CafeStatUpdateTracker() }
        context = CafeUpdateNotificationContext(
            userID: userID, favoriteIDs: favoriteIDs, location: location,
            radiusKilometers: radiusKilometers, enabled: enabled
        )
    }

    func receive(cafe: CafeSnapshot, latest: CafeCheckIn?) {
        guard let report = tracker.consume(cafeID: cafe.id, latest: latest),
              context.isEligible(cafe: cafe), let userID = context.userID
        else { return }

        let taskID = UUID()
        deliveryTasks[taskID] = Task { [weak self] in
            guard let self else { return }
            defer { self.deliveryTasks[taskID] = nil }
            do {
                try await service.sendCafeUpdate(cafe: cafe, report: report, userID: userID)
            } catch is CancellationError {
                // A setting, location, favourite, or session changed before delivery.
            } catch {
                logger.error("Couldn’t deliver café update: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func stop() {
        context.enabled = false
        cancelDelivery()
    }

    private func cancelDelivery() {
        for task in deliveryTasks.values { task.cancel() }
        deliveryTasks.removeAll()
    }
}
