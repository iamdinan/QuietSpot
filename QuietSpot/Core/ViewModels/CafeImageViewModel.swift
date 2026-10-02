import Observation
import UIKit

@MainActor
@Observable
final class CafeImageViewModel {
    private(set) var image: UIImage?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    @ObservationIgnored private var requestedID: String?

    func load(cafeID: String) async {
        requestedID = cafeID
        image = nil
        errorMessage = nil
        isLoading = true
        defer {
            if requestedID == cafeID { isLoading = false }
        }

        do {
            let loadedImage = try await CafeImageService.shared.image(for: cafeID)
            try Task.checkCancellation()
            guard requestedID == cafeID else { return }
            image = loadedImage
        } catch is CancellationError {
            // The image view disappeared; other views can still use the shared request.
        } catch {
            guard requestedID == cafeID else { return }
            errorMessage = error.localizedDescription
        }
    }
}
