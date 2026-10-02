import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class CommunityService {
    private var posts: CollectionReference { Firestore.firestore().collection("communityPosts") }

    func observePosts(onChange: @escaping (Result<[CafeInsight], Error>) -> Void) -> ListenerRegistration {
        posts.order(by: "createdAt", descending: true)
            .addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
                Task { @MainActor in
                    if let error { onChange(.failure(error)); return }
                    guard let snapshot, !snapshot.metadata.hasPendingWrites else { return }
                    if snapshot.metadata.isFromCache && snapshot.documents.isEmpty { return }
                    do {
                        let insights = try snapshot.documents.map { document in
                            let post = try document.data(as: CafeInsightDocument.self)
                            guard post.likeCount >= 0 else { throw CocoaError(.coderReadCorrupt) }
                            return CafeInsight(id: document.documentID, cafeID: post.cafeID,
                                text: post.text, createdAt: post.createdAt.dateValue(),
                                authorID: post.authorID, likeCount: post.likeCount)
                        }
                        onChange(.success(insights))
                    } catch { onChange(.failure(error)) }
                }
            }
    }

    func share(cafeID: String, text: String, userID: String) async throws {
        guard Auth.auth().currentUser?.uid == userID else { throw CocoaError(.userCancelled) }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 2_000 else {
            throw NSError(domain: "Community", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Write an insight between 1 and 2,000 characters."
            ])
        }
        let data: [String: Any] = [
            "cafeID": cafeID, "authorID": userID, "text": trimmed,
            "createdAt": FieldValue.serverTimestamp(), "likeCount": 0
        ]
        let reference = posts.document()
        try await reference.setData(data)
    }

    func observeLike(postID: String, userID: String, onChange: @escaping (Result<Bool, Error>) -> Void) -> ListenerRegistration {
        posts.document(postID).collection("likes").document(userID)
            .addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
                Task { @MainActor in
                    if let error { onChange(.failure(error)); return }
                    guard let snapshot, !snapshot.metadata.hasPendingWrites else { return }
                    if snapshot.metadata.isFromCache && !snapshot.exists { return }
                    onChange(.success(snapshot.exists))
                }
            }
    }

    func setLiked(postID: String, userID: String, liked: Bool) async throws {
        guard Auth.auth().currentUser?.uid == userID else { throw CocoaError(.userCancelled) }
        let post = posts.document(postID)
        let like = post.collection("likes").document(userID)
        // Read both documents before writing. Firestore retries concurrent changes.
        _ = try await Firestore.firestore().runTransaction { transaction, errorPointer in
            do {
                let postSnapshot = try transaction.getDocument(post)
                let likeSnapshot = try transaction.getDocument(like)
                guard let count = postSnapshot.get("likeCount") as? Int, count >= 0 else {
                    throw CocoaError(.coderReadCorrupt)
                }
                if likeSnapshot.exists != liked {
                    if liked {
                        transaction.setData(["createdAt": FieldValue.serverTimestamp()], forDocument: like)
                    } else {
                        guard count > 0 else { throw CocoaError(.coderReadCorrupt) }
                        transaction.deleteDocument(like)
                    }
                    transaction.updateData(["likeCount": count + (liked ? 1 : -1)], forDocument: post)
                }
            } catch { errorPointer?.pointee = error as NSError }
            return nil
        }
    }
}
