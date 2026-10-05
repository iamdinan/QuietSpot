import CoreLocation

struct CafeUpdateNotificationContext {
    var userID: String? = nil
    var favoriteIDs: Set<String> = []
    var location: CLLocation? = nil
    var radiusKilometers = 5.0
    var enabled = false

    func isEligible(cafe: CafeSnapshot) -> Bool {
        guard enabled, userID != nil, favoriteIDs.contains(cafe.id),
              let location, location.horizontalAccuracy >= 0,
              radiusKilometers.isFinite, radiusKilometers > 0 else { return false }
        return location.distance(from: CLLocation(latitude: cafe.latitude, longitude: cafe.longitude)) <= radiusKilometers * 1000
    }
}
