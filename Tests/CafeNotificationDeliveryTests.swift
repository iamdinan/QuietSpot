import Foundation
import CoreLocation

// The macOS harness injects its sender; the app's real sender uses iOS-only APIs.
@MainActor
struct NotificationService {
    func sendCafeUpdate(cafe: CafeSnapshot, report: CafeCheckIn, userID: String) async throws {
        fatalError("Delivery tests must inject their suspended sender")
    }
}

/// Holds delivery at its permission-check suspension point without involving iOS UI.
@MainActor
private final class SuspendedDelivery {
    private var gate: CheckedContinuation<Void, Never>?
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var finishWaiter: CheckedContinuation<Void, Never>?
    private var didFinish = false
    private(set) var delivered = false

    func send() async throws {
        defer {
            didFinish = true
            finishWaiter?.resume()
            finishWaiter = nil
        }
        await withCheckedContinuation { continuation in
            gate = continuation
            startWaiter?.resume()
            startWaiter = nil
        }
        try Task.checkCancellation()
        delivered = true
    }

    func waitForStart() async {
        if gate != nil { return }
        await withCheckedContinuation { startWaiter = $0 }
    }

    func finish() async {
        gate?.resume()
        gate = nil
        if didFinish { return }
        await withCheckedContinuation { finishWaiter = $0 }
    }
}

@main
struct CafeNotificationDeliveryTests {
    @MainActor
    static func main() async {
        let cafe = CafeSnapshot(id: "cafe", name: "Test Café", area: "Colombo", description: "",
                                latitude: 6.9147, longitude: 79.8610)
        let nearby = CLLocation(latitude: cafe.latitude, longitude: cafe.longitude)
        let outsideRadius = CLLocation(latitude: cafe.latitude + 0.1, longitude: cafe.longitude)
        func update(_ monitor: CafeUpdateNotificationMonitor, user: String? = "user",
                    favourites: Set<String> = ["cafe"], location: CLLocation? = nearby,
                    enabled: Bool = true) {
            monitor.updateContext(userID: user, favoriteIDs: favourites, location: location,
                                  radiusKilometers: 5, enabled: enabled)
        }
        func run(change: (CafeUpdateNotificationMonitor) -> Void) async -> Bool {
            let delivery = SuspendedDelivery()
            let monitor = CafeUpdateNotificationMonitor { _, _, _ in try await delivery.send() }
            update(monitor)
            let date = Date()
            let baseline = CafeCheckIn(id: "old", createdAt: date, time: "just now", noiseLevel: .quiet,
                                       wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded")
            let changed = CafeCheckIn(id: "new", createdAt: date.addingTimeInterval(1), time: "just now",
                                      noiseLevel: .loud, wifi: baseline.wifi, outlets: baseline.outlets, crowd: baseline.crowd)
            monitor.receive(cafe: cafe, latest: baseline)
            monitor.receive(cafe: cafe, latest: changed)
            await delivery.waitForStart()
            change(monitor)
            await delivery.finish()
            return delivery.delivered
        }

        let refreshDelivered = await run { update($0) }
        assert(refreshDelivered, "An unchanged context must not cancel a pending alert")
        let movementDelivered = await run {
            update($0, location: CLLocation(latitude: cafe.latitude + 0.001, longitude: cafe.longitude))
        }
        assert(movementDelivered, "An eligible location refresh must preserve pending delivery")
        let favouritesDelivered = await run { update($0, favourites: ["cafe", "other"]) }
        assert(favouritesDelivered, "Adding another favourite must not cancel this café's alert")
        let disabledDelivered = await run { update($0, enabled: false) }
        assert(!disabledDelivered)
        let removedDelivered = await run { update($0, favourites: []) }
        assert(!removedDelivered)
        let distantDelivered = await run { update($0, location: outsideRadius) }
        assert(!distantDelivered)
        let missingLocationDelivered = await run { update($0, location: nil) }
        assert(!missingLocationDelivered)
        let switchedAccountDelivered = await run { update($0, user: "another-user") }
        assert(!switchedAccountDelivered, "An old account's pending alert must not be delivered")
        let signedOutDelivered = await run { update($0, user: nil) }
        assert(!signedOutDelivered)
        let stoppedDelivered = await run { $0.stop() }
        assert(!stoppedDelivered)
        print("Café notification delivery race checks passed")
    }
}
