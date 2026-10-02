import FirebaseCore
import FirebaseFirestore
import UIKit

@MainActor
final class CafeImageService {
    static let shared = CafeImageService()

    private let cache = NSCache<NSString, UIImage>()
    private var pending: [String: Task<UIImage, Error>] = [:]

    private init() {
        cache.countLimit = 20
        cache.totalCostLimit = 20 * 1024 * 1024
    }

    func image(for cafeID: String) async throws -> UIImage {
        if let image = cache.object(forKey: cafeID as NSString) { return image }
        if let task = pending[cafeID] { return try await task.value }

        // Share concurrent requests from cards, thumbnails, and details.
        let task = Task { try await fetchImage(for: cafeID) }
        pending[cafeID] = task
        defer { pending[cafeID] = nil }
        return try await task.value
    }

    private func fetchImage(for cafeID: String) async throws -> UIImage {
        guard FirebaseApp.app() != nil else { throw ImageError.notConfigured }
        let document = try await Firestore.firestore()
            .collection("cafeImages").document(cafeID)
            .getDocument(source: .server)
        guard document.exists else { throw ImageError.missingDocument }
        let record = try document.data(as: ImageDocument.self)
        let base64 = record.imageBase64.filter { !$0.isWhitespace }
        guard let data = Data(base64Encoded: base64),
              let image = UIImage(data: data) else { throw ImageError.invalidImage }

        let pixelCost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? data.count
        cache.setObject(image, forKey: cafeID as NSString, cost: pixelCost)
        return image
    }

    private struct ImageDocument: Decodable {
        let imageBase64: String
    }

    private enum ImageError: LocalizedError {
        case notConfigured, missingDocument, invalidImage

        var errorDescription: String? {
            switch self {
            case .notConfigured: "Firebase is not configured."
            case .missingDocument: "No image document exists with this café’s document ID."
            case .invalidImage: "The imageBase64 field does not contain a valid encoded image."
            }
        }
    }
}
