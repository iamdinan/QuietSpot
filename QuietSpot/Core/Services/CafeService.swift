import FirebaseFirestore
import FirebaseCore
import Foundation

@MainActor
struct CafeService {
    /// Call after Firebase is configured and the user has signed in.
    func fetchCafes() async throws -> [CafeDocument] {
        guard FirebaseApp.app() != nil else {
            throw NSError(domain: "CafeService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Firebase is not configured. Run the app with its GoogleService-Info.plist."
            ])
        }
        let snapshot = try await Firestore.firestore()
            .collection("cafes")
            .getDocuments(source: .server)

        // Propagate decoding errors rather than silently dropping café documents.
        return try snapshot.documents.map { document in
            try document.data(as: CafeDocument.self)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
