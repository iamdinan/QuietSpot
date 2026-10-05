import CoreLocation
import Combine

@MainActor
final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var permissionDenied = false
    @Published private(set) var isApproximate = false
    @Published private(set) var errorMessage: String?

    private let manager = CLLocationManager()
    private var isActive = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100
    }

    func start(requestPermission: Bool = true) {
        isActive = true
        errorMessage = nil
        updateAuthorization()
        if requestPermission && manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func stop() {
        isActive = false
        manager.stopUpdatingLocation()
        currentLocation = nil
    }

    private func updateAuthorization() {
        permissionDenied = manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted
        isApproximate = manager.accuracyAuthorization == .reducedAccuracy
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if isActive { manager.startUpdatingLocation() }
        case .denied, .restricted:
            manager.stopUpdatingLocation()
            currentLocation = nil
        case .notDetermined: break
        @unknown default: break
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in self?.updateAuthorization() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Reject old cached fixes when starting tracking. Once accepted, a fix
        // remains useful while tracking a stationary user until tracking stops.
        guard let latest = locations.last, latest.horizontalAccuracy >= 0,
              abs(latest.timestamp.timeIntervalSinceNow) <= 300 else { return }
        Task { @MainActor [weak self] in
            guard let self, self.isActive else { return }
            self.currentLocation = latest
            self.errorMessage = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let isTemporary = (error as? CLError)?.code == .locationUnknown
        Task { @MainActor [weak self] in
            guard let self, self.isActive, !isTemporary else { return }
            self.errorMessage = "Your location couldn’t be found. You can still browse the Colombo cafés."
        }
    }
}
