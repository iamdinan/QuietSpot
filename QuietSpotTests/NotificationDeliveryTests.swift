import CoreLocation
import Foundation
import Testing
@testable import QuietSpot

/// Suspends at the sender's permission-check await, then deterministically resumes delivery.
@MainActor
private final class DeliveryGate {
    private var gate: CheckedContinuation<Void, Never>?
    private var started: CheckedContinuation<Void, Never>?
    private var finished: CheckedContinuation<Void, Never>?
    private var didFinish = false
    private(set) var delivered = false

    func send() async throws {
        defer {
            didFinish = true
            finished?.resume()
            finished = nil
        }
        await withCheckedContinuation {
            gate = $0
            started?.resume()
            started = nil
        }
        try Task.checkCancellation()
        delivered = true
    }

    func waitUntilStarted() async {
        if gate != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func releaseAndWait() async {
        gate?.resume()
        gate = nil
        if didFinish { return }
        await withCheckedContinuation { finished = $0 }
    }
}

@Suite("Pending notification delivery")
@MainActor
struct NotificationDeliveryTests {
    @Test("Context refreshes preserve eligible alerts and cancel ineligible alerts", .timeLimit(.minutes(1)),
          arguments: ["unchanged", "nearby movement", "another favourite", "disabled", "unfavourited",
                      "outside radius", "missing location", "switched account", "signed out", "stopped"])
    func contextChanges(change: String) async {
        let gate = DeliveryGate()
        let monitor = CafeUpdateNotificationMonitor { _, _, _ in try await gate.send() }
        let cafe = Fixtures.cafe()
        var userID: String? = "user"
        var favourites: Set<String> = [cafe.id]
        var location: CLLocation? = CLLocation(latitude: cafe.latitude, longitude: cafe.longitude)
        var enabled = true
        func updateContext() {
            monitor.updateContext(userID: userID, favoriteIDs: favourites, location: location,
                                  radiusKilometers: 3, enabled: enabled)
        }
        updateContext()
        monitor.receive(cafe: cafe, latest: Fixtures.report(id: "baseline"))
        monitor.receive(cafe: cafe, latest: Fixtures.report(id: "changed", offset: 1, noise: .loud))
        await gate.waitUntilStarted()
        switch change {
        case "nearby movement": location = CLLocation(latitude: cafe.latitude + 0.001, longitude: cafe.longitude)
        case "another favourite": favourites.insert("another")
        case "disabled": enabled = false
        case "unfavourited": favourites = []
        case "outside radius": location = CLLocation(latitude: cafe.latitude + 0.1, longitude: cafe.longitude)
        case "missing location": location = nil
        case "switched account": userID = "other-user"
        case "signed out": userID = nil
        case "stopped": monitor.stop()
        default: break
        }
        if change != "stopped" { updateContext() }
        await gate.releaseAndWait()
        #expect(gate.delivered == ["unchanged", "nearby movement", "another favourite"].contains(change))
    }
}
