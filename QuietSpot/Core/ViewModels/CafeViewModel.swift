import Foundation
import FirebaseFirestore
import Observation

@MainActor
@Observable
final class CafeViewModel {
    var cafes: [CafeSnapshot] = []
    private(set) var isLoading = false
    private var loadingError: String?
    private var statusErrors: [String: String] = [:]
    var errorMessage: String? { loadingError ?? statusErrors.sorted { $0.key < $1.key }.first?.value }
    @ObservationIgnored private let service = CafeService()
    @ObservationIgnored private let checkInService = CafeCheckInService()
    @ObservationIgnored private var statusListeners: [String: ListenerRegistration] = [:]
    @ObservationIgnored private var listenerGeneration = UUID()
    @ObservationIgnored private var favoriteIDs: Set<String> = []

    func updateFavorites(_ ids: Set<String>) {
        favoriteIDs = ids
        for index in cafes.indices { cafes[index].isFavorite = ids.contains(cafes[index].id) }
    }

    deinit {
        for listener in statusListeners.values { listener.remove() }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        loadingError = nil
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
                    isFavorite: favoriteIDs.contains(id)
                )
                // Keep confirmed reports visible while refreshed listeners reconnect.
                if let history = previous?.checkInHistory {
                    cafe.updateCheckIns(history)
                } else {
                    cafe.isLoadingStatus = true
                }
                return cafe
            }
            observeStatuses()
        } catch is CancellationError {
            // The signed-in screen may have disappeared.
        } catch {
            loadingError = "Couldn’t load cafés. \(error.localizedDescription)"
        }
    }

    private func observeStatuses() {
        for listener in statusListeners.values { listener.remove() }
        statusListeners.removeAll()
        statusErrors.removeAll()
        listenerGeneration = UUID()
        let generation = listenerGeneration

        for cafe in cafes {
            let cafeID = cafe.id
            statusListeners[cafeID] = checkInService.observeLatest(cafeID: cafeID) { [weak self] result in
                guard let self, self.listenerGeneration == generation,
                      let index = self.cafes.firstIndex(where: { $0.id == cafeID }) else { return }
                switch result {
                case .success(let checkIns):
                    self.cafes[index].updateCheckIns(checkIns)
                    self.statusErrors[cafeID] = nil
                case .failure(let error):
                    let message = "Couldn’t load check-ins for \(self.cafes[index].name). \(error.localizedDescription)"
                    self.cafes[index].isLoadingStatus = false
                    self.cafes[index].statusErrorMessage = message
                    self.statusErrors[cafeID] = message
                }
            }
        }
    }
}
