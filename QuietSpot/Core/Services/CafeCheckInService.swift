import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation

@MainActor
struct CafeCheckInService {
    func submit(cafeID: String, noise: NoiseLevel, wifi: String, outlets: String, crowd: String) async throws {
        try NetworkStatus.shared.requireConnection()
        guard FirebaseApp.app() != nil else {
            throw NSError(domain: "CafeCheckIn", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Firebase is not configured. Run the app before submitting a check-in."
            ])
        }
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "CafeCheckIn", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Please sign in before submitting a check-in."
            ])
        }
        // Completion waits for server acknowledgement; queued offline writes aren't success.
        try await Firestore.firestore().collection("cafes").document(cafeID)
            .collection("checkIns").document().setData([
                "authorID": userID,
                "createdAt": FieldValue.serverTimestamp(),
                "noiseLevel": noise.rawValue,
                "wifi": wifi,
                "outlets": outlets,
                "crowd": crowd
            ])
    }

    func observeLatest(
        cafeID: String,
        onConfirmedChange: (([CafeCheckIn]) -> Void)? = nil,
        onChange: @escaping (Result<[CafeCheckIn], Error>) -> Void
    ) -> ListenerRegistration {
        Firestore.firestore().collection("cafes").document(cafeID)
            .collection("checkIns")
            .order(by: "createdAt", descending: true)
            .limit(to: 3)
            .addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
                Task { @MainActor in
                    if let error {
                        onChange(.failure(error))
                        return
                    }
                    // Don't display an unconfirmed local check-in as a saved report.
                    guard let snapshot, !snapshot.metadata.hasPendingWrites else { return }
                    // An empty cache doesn't prove the server has no check-ins.
                    if !OfflineQueryCache().canUseSnapshot(
                        key: "checkIns/" + cafeID, isFromCache: snapshot.metadata.isFromCache,
                        isEmpty: snapshot.documents.isEmpty
                    ) {
                        if NetworkStatus.shared.isOffline { onChange(.failure(OfflineBrowsingError.noCachedData)) }
                        return
                    }
                    do {
                        let checkIns = try snapshot.documents.map { document in
                            let report = try document.data(as: CafeCheckInDocument.self)
                            let date = report.createdAt.dateValue()
                            return CafeCheckIn(
                                id: document.documentID, createdAt: date,
                                time: CafeCheckInTimeFormatter.string(from: date),
                                noiseLevel: report.noiseLevel, wifi: report.wifi,
                                outlets: report.outlets, crowd: report.crowd
                            )
                        }
                        onChange(.success(checkIns))
                        if !snapshot.metadata.isFromCache { onConfirmedChange?(checkIns) }
                    } catch {
                        onChange(.failure(error))
                    }
                }
            }
    }
}
