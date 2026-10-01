import Foundation

struct CafeInsight: Identifiable {
    let id = UUID()
    let cafeID: UUID
    let authorName: String
    let text: String
    let createdAt: Date
    var authorID: UUID? = nil
    var otherLikeCount: Int = 0
    var isLiked = false

    var isCurrentUser: Bool {
        authorID == UserProfile.localUserID
    }

    var likeCount: Int {
        otherLikeCount + (isLiked ? 1 : 0)
    }
}
