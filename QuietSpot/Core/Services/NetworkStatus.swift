import Foundation
import Network
import Observation

/// Tracks connectivity, not whether Firebase itself is reachable.
@MainActor
@Observable
final class NetworkStatus {
    static let shared = NetworkStatus()
    private(set) var isOffline = false
    @ObservationIgnored private let monitor = NWPathMonitor()

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let offline = path.status != .satisfied
            Task { @MainActor [weak self] in self?.isOffline = offline }
        }
        monitor.start(queue: DispatchQueue(label: "QuietSpot.connectivity"))
    }

    func requireConnection() throws {
        if isOffline { throw OfflineBrowsingError.connectionRequired }
    }
}

enum OfflineBrowsingError: LocalizedError {
    case connectionRequired, noCachedData

    var errorDescription: String? {
        switch self {
        case .connectionRequired: "Connect to the internet to save changes."
        case .noCachedData: "This content hasn’t been downloaded. Connect to the internet to load it."
        }
    }
}
