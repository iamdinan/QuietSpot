import FirebaseFirestore
import Foundation

@MainActor
struct UserDataService {
    private func user(_ id: String) -> DocumentReference {
        Firestore.firestore().collection("users").document(id)
    }

    func createProfileIfNeeded(userID: String, displayName: String) async throws {
        let reference = user(userID)
        _ = try await Firestore.firestore().runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(reference)
                if !snapshot.exists {
                    transaction.setData([
                        "displayName": displayName,
                        "photoBase64": "",
                        "createdAt": FieldValue.serverTimestamp(),
                        "updatedAt": FieldValue.serverTimestamp()
                    ], forDocument: reference)
                }
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }

    func observeProfile(userID: String, onChange: @escaping (Result<UserProfile, Error>) -> Void) -> ListenerRegistration {
        user(userID).addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
            Task { @MainActor in
                if let error { onChange(.failure(error)); return }
                guard let snapshot, !snapshot.metadata.hasPendingWrites else { return }
                if !snapshot.exists && snapshot.metadata.isFromCache { return }
                do {
                    guard let name = snapshot.get("displayName") as? String,
                          let encoded = snapshot.get("photoBase64") as? String else {
                        throw CocoaError(.coderReadCorrupt)
                    }
                    let photo = encoded.isEmpty ? nil : Data(base64Encoded: encoded)
                    if !encoded.isEmpty && photo == nil { throw CocoaError(.coderReadCorrupt) }
                    onChange(.success(UserProfile(id: userID, displayName: name, photoData: photo)))
                } catch { onChange(.failure(error)) }
            }
        }
    }

    func saveProfile(userID: String, displayName: String, photoData: Data?) async throws {
        guard !displayName.isEmpty, displayName.count <= 100 else {
            throw NSError(domain: "UserData", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Use a display name between 1 and 100 characters."
            ])
        }
        let encoded = photoData?.base64EncodedString() ?? ""
        // Leave room below Firestore's document limit for the other profile fields.
        guard encoded.utf8.count <= 700_000 else {
            throw NSError(domain: "UserData", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "This profile photo is too large. Please choose a smaller photo."
            ])
        }
        try await user(userID).updateData([
            "displayName": displayName, "photoBase64": encoded,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func observeFavorites(userID: String, onChange: @escaping (Result<Set<String>, Error>) -> Void) -> ListenerRegistration {
        user(userID).collection("favorites").addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
            Task { @MainActor in
                if let error { onChange(.failure(error)); return }
                guard let snapshot, !snapshot.metadata.hasPendingWrites else { return }
                if snapshot.metadata.isFromCache && snapshot.documents.isEmpty { return }
                onChange(.success(Set(snapshot.documents.map(\.documentID))))
            }
        }
    }

    func setFavorite(userID: String, cafeID: String, enabled: Bool) async throws {
        let reference = user(userID).collection("favorites").document(cafeID)
        if enabled {
            try await reference.setData(["createdAt": FieldValue.serverTimestamp()])
        } else {
            try await reference.delete()
        }
    }
}
