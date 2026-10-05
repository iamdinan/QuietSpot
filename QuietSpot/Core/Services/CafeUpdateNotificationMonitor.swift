import CoreLocation
import OSLog

@MainActor
final class CafeUpdateNotificationMonitor {
    private var tracker = CafeStatUpdateTracker()
    private var context = CafeUpdateNotificationContext()
    private struct Delivery {
        let cafe: CafeSnapshot
        let userID: String
        let task: Task<Void, Never>
    }
    private var deliveryTasks: [UUID: Delivery] = [:]
    private let sendUpdate: (CafeSnapshot, CafeCheckIn, String) async throws -> Void
    private let logger = Logger(subsystem: "dinan.QuietSpot", category: "CafeNotifications")

    init(sendUpdate: @escaping (CafeSnapshot, CafeCheckIn, String) async throws -> Void = {
        try await NotificationService().sendCafeUpdate(cafe: $0, report: $1, userID: $2)
    }) {
        self.sendUpdate = sendUpdate
    }

    func updateContext(
        userID: String?, favoriteIDs: Set<String>, location: CLLocation?,
        radiusKilometers: Double, enabled: Bool
    ) {
        if context.userID != userID { tracker = CafeStatUpdateTracker() }
        context = CafeUpdateNotificationContext(
            userID: userID, favoriteIDs: favoriteIDs, location: location,
            radiusKilometers: radiusKilometers, enabled: enabled
        )
        // A routine location/profile refresh must not discard an eligible alert.
        for id in Array(deliveryTasks.keys) {
            guard let delivery = deliveryTasks[id] else { continue }
            if delivery.userID != context.userID || !context.isEligible(cafe: delivery.cafe) {
                delivery.task.cancel()
                deliveryTasks[id] = nil
            }
        }
    }

    func receive(cafe: CafeSnapshot, latest: CafeCheckIn?) {
        guard let report = tracker.consume(cafeID: cafe.id, latest: latest) else {
            logger.debug("No new changed report for café \(cafe.id, privacy: .public)")
            return
        }
        guard context.isEligible(cafe: cafe), let userID = context.userID else {
            logger.debug("Café alert skipped: enabled=\(self.context.enabled), favourite=\(self.context.favoriteIDs.contains(cafe.id)), locationAvailable=\(self.context.location != nil), radiusKm=\(self.context.radiusKilometers)")
            return
        }

        let taskID = UUID()
        let task = Task { [weak self] in
            guard let self else { return }
            defer { self.deliveryTasks[taskID] = nil }
            do {
                try Task.checkCancellation()
                try await sendUpdate(cafe, report, userID)
            } catch is CancellationError {
                // A setting, location, favourite, or session changed before delivery.
            } catch {
                logger.error("Couldn’t deliver café update: \(error.localizedDescription, privacy: .public)")
            }
        }
        deliveryTasks[taskID] = Delivery(cafe: cafe, userID: userID, task: task)
    }

    func stop() {
        context.enabled = false
        cancelDelivery()
    }

    private func cancelDelivery() {
        for delivery in deliveryTasks.values { delivery.task.cancel() }
        deliveryTasks.removeAll()
    }
}
