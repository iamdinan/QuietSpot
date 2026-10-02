import Foundation
import Observation

@MainActor
@Observable
final class CafeCheckInViewModel {
    private(set) var isSubmitting = false
    var errorMessage: String?
    @ObservationIgnored private let service = CafeCheckInService()

    func submit(cafeID: String, noise: NoiseLevel, wifi: String, outlets: String, crowd: String) async -> Bool {
        guard !isSubmitting else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            try await service.submit(cafeID: cafeID, noise: noise, wifi: wifi, outlets: outlets, crowd: crowd)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
