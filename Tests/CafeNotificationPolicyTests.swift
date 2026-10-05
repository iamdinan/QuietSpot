// Standalone regression checks; run with Tests/run-cafe-notification-tests.sh.
import Foundation
import CoreLocation

@main
struct CafeNotificationPolicyTests {
    @MainActor
    static func main() {
        let now = Date()
        func report(_ id: String, seconds: Double, noise: NoiseLevel = .quiet,
                    wifi: String = "Strong", outlets: String = "Available", crowd: String = "Low") -> CafeCheckIn {
            CafeCheckIn(id: id, createdAt: now.addingTimeInterval(seconds), time: "Just now",
                        noiseLevel: noise, wifi: wifi, outlets: outlets, crowd: crowd)
        }
        var tracker = CafeStatUpdateTracker()
        let initial = report("initial", seconds: 0)
        assert(tracker.consume(cafeID: "cafe", latest: initial) == nil, "Initial load must be silent")
        assert(tracker.consume(cafeID: "cafe", latest: initial) == nil, "Metadata repeats must be silent")
        assert(tracker.consume(cafeID: "cafe", latest: report("same-stats", seconds: 1)) == nil)
        let changed = report("changed", seconds: 2, noise: .loud)
        assert(tracker.consume(cafeID: "cafe", latest: changed)?.id == "changed")
        assert(tracker.consume(cafeID: "cafe", latest: initial) == nil, "Older snapshots must be silent")
        assert(tracker.consume(cafeID: "cafe", latest: nil) == nil)
        assert(tracker.consume(cafeID: "cafe", latest: changed) == nil, "Deletion/reconnect must not replay")
        assert(tracker.consume(cafeID: "other", latest: nil) == nil)
        assert(tracker.consume(cafeID: "other", latest: initial)?.id == "initial", "First report after confirmed empty is new")
        for (id, next) in [
            ("wifi", report("wifi", seconds: 3, noise: .loud, wifi: "Weak")),
            ("outlets", report("outlets", seconds: 4, noise: .loud, wifi: "Weak", outlets: "Full")),
            ("crowd", report("crowd", seconds: 5, noise: .loud, wifi: "Weak", outlets: "Full", crowd: "High"))
        ] {
            assert(tracker.consume(cafeID: "cafe", latest: next)?.id == id)
            assert(tracker.consume(cafeID: "cafe", latest: next) == nil)
        }

        let cafe = CafeSnapshot(id: "cafe", name: "Test Café", area: "Colombo", description: "",
                                latitude: 6.9147, longitude: 79.8610)
        let location = CLLocation(coordinate: cafe.coordinate, altitude: 0,
                                  horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: now)
        var notificationContext = CafeUpdateNotificationContext()
        func context(user: String? = "user", favorites: Set<String> = ["cafe"],
                     position: CLLocation? = location, radius: Double = 5, enabled: Bool = true) {
            notificationContext = CafeUpdateNotificationContext(userID: user, favoriteIDs: favorites, location: position,
                                  radiusKilometers: radius, enabled: enabled)
        }
        context()
        assert(notificationContext.isEligible(cafe: cafe))
        context(favorites: [])
        assert(!notificationContext.isEligible(cafe: cafe), "Unfavourited cafés must be excluded")
        context(enabled: false)
        assert(!notificationContext.isEligible(cafe: cafe))
        context(user: nil)
        assert(!notificationContext.isEligible(cafe: cafe))
        context(position: nil)
        assert(!notificationContext.isEligible(cafe: cafe))
        context()
        let distant = CLLocation(latitude: cafe.latitude + 0.02, longitude: cafe.longitude)
        context(position: distant, radius: 1)
        assert(!notificationContext.isEligible(cafe: cafe))
        context(position: distant, radius: 5)
        assert(notificationContext.isEligible(cafe: cafe), "Radius changes must affect eligibility")
        context(radius: .nan)
        assert(!notificationContext.isEligible(cafe: cafe))
        context()
        notificationContext.enabled = false
        assert(!notificationContext.isEligible(cafe: cafe), "Stopped sessions must not deliver")
        print("Café notification regression checks passed")
    }
}
