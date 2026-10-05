import CoreLocation
import Foundation
import Testing
@testable import QuietSpot

@Suite("Notification change detection and eligibility")
@MainActor
struct NotificationPolicyTests {
    @Test("First load and identical stats are silent; a changed report alerts once")
    func baselineAndDuplicates() {
        var tracker = CafeStatUpdateTracker()
        let initial = Fixtures.report(id: "initial")
        #expect(tracker.consume(cafeID: "cafe", latest: initial) == nil)
        #expect(tracker.consume(cafeID: "cafe", latest: initial) == nil)
        #expect(tracker.consume(cafeID: "cafe", latest: Fixtures.report(id: "same", offset: 1)) == nil)
        let changed = Fixtures.report(id: "changed", offset: 2, noise: .loud)
        #expect(tracker.consume(cafeID: "cafe", latest: changed)?.id == "changed")
        #expect(tracker.consume(cafeID: "cafe", latest: changed) == nil)
        #expect(tracker.consume(cafeID: "cafe", latest: initial) == nil)
        #expect(tracker.consume(cafeID: "cafe", latest: nil) == nil)
        #expect(tracker.consume(cafeID: "cafe", latest: changed) == nil)
    }

    @Test("Changing any individual stat qualifies", arguments: ["noise", "wifi", "outlets", "crowd"])
    func eachStatCanTrigger(stat: String) {
        var tracker = CafeStatUpdateTracker()
        _ = tracker.consume(cafeID: "cafe", latest: Fixtures.report())
        let next = Fixtures.report(id: "new", offset: 1, noise: stat == "noise" ? .loud : .quiet,
            wifi: stat == "wifi" ? "Spotty Wi‑Fi" : "Strong Wi‑Fi",
            outlets: stat == "outlets" ? "Outlets full" : "Outlets free",
            crowd: stat == "crowd" ? "Crowded" : "Uncrowded")
        #expect(tracker.consume(cafeID: "cafe", latest: next)?.id == "new")
    }

    @Test("Older, equal-time and undated reports cannot replay alerts")
    func invalidNewReportDates() {
        var tracker = CafeStatUpdateTracker()
        _ = tracker.consume(cafeID: "cafe", latest: Fixtures.report())
        #expect(tracker.consume(cafeID: "cafe", latest: Fixtures.report(id: "equal", noise: .loud)) == nil)
        #expect(tracker.consume(cafeID: "cafe", latest: Fixtures.report(id: "older", offset: -1, noise: .loud)) == nil)
        var undated = Fixtures.report(id: "undated", offset: 1, noise: .loud)
        undated.createdAt = nil
        #expect(tracker.consume(cafeID: "cafe", latest: undated) == nil)
        #expect(tracker.consume(cafeID: "cafe", latest: Fixtures.report(id: "valid", offset: 1, noise: .loud))?.id == "valid")
    }

    @Test("First report after a confirmed empty history alerts, independently per café")
    func emptyHistoryAndCafeIsolation() {
        var tracker = CafeStatUpdateTracker()
        #expect(tracker.consume(cafeID: "a", latest: nil) == nil)
        #expect(tracker.consume(cafeID: "a", latest: Fixtures.report())?.id == "report")
        #expect(tracker.consume(cafeID: "b", latest: Fixtures.report()) == nil)
    }

    @Test("Eligibility requires an enabled, signed-in favourite and a valid nearby location")
    func eligibilityGates() {
        let cafe = Fixtures.cafe()
        var context = CafeUpdateNotificationContext(userID: "user", favoriteIDs: [cafe.id],
            location: CLLocation(latitude: cafe.latitude, longitude: cafe.longitude), radiusKilometers: 3, enabled: true)
        #expect(context.isEligible(cafe: cafe))
        context.enabled = false
        #expect(!context.isEligible(cafe: cafe))
        context.enabled = true
        context.userID = nil
        #expect(!context.isEligible(cafe: cafe))
        context.userID = "user"
        context.favoriteIDs = []
        #expect(!context.isEligible(cafe: cafe))
        context.favoriteIDs = [cafe.id]
        context.location = nil
        #expect(!context.isEligible(cafe: cafe))
        context.location = CLLocation(coordinate: cafe.coordinate, altitude: 0,
            horizontalAccuracy: -1, verticalAccuracy: 0, timestamp: Fixtures.now)
        #expect(!context.isEligible(cafe: cafe))
    }

    @Test("Invalid radii never qualify", arguments: [0.0, -1.0, Double.nan, Double.infinity])
    func invalidRadius(radius: Double) {
        let cafe = Fixtures.cafe()
        let context = CafeUpdateNotificationContext(userID: "user", favoriteIDs: [cafe.id],
            location: CLLocation(latitude: cafe.latitude, longitude: cafe.longitude), radiusKilometers: radius, enabled: true)
        #expect(!context.isEligible(cafe: cafe))
    }

    @Test("Changing the radius changes eligibility for the same location")
    func distanceFilter() {
        let cafe = Fixtures.cafe()
        var context = CafeUpdateNotificationContext(userID: "user", favoriteIDs: [cafe.id],
            location: CLLocation(latitude: cafe.latitude + 0.02, longitude: cafe.longitude), radiusKilometers: 1, enabled: true)
        #expect(!context.isEligible(cafe: cafe))
        context.radiusKilometers = 3
        #expect(context.isEligible(cafe: cafe))
    }
}
