import Foundation
import FirebaseFirestore
import Observation

@MainActor
@Observable
final class CafeViewModel {
    var cafes: [CafeSnapshot] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    @ObservationIgnored private let service = CafeService()

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let documents = try await service.fetchCafes()
            cafes = try documents.map { document in
                guard let id = document.id else {
                    throw CocoaError(.coderReadCorrupt)
                }
                let previous = cafes.first { $0.id == id }
                var cafe = CafeSnapshot(
                    id: id, name: document.name, area: document.area,
                    description: document.description,
                    latitude: document.location.latitude,
                    longitude: document.location.longitude,
                    isFavorite: previous?.isFavorite ?? false
                )
                // Preserve session-only check-ins during a metadata refresh.
                if let previous, let latest = previous.recentCheckIns.first {
                    cafe.record(latest)
                    cafe.checkInHistory = previous.recentCheckIns
                    cafe.updateOrder = previous.updateOrder
                }
                return cafe
            }
        } catch is CancellationError {
            // The signed-in screen may have disappeared.
        } catch {
            errorMessage = "Couldn’t load cafés. \(error.localizedDescription)"
        }
    }
}
