import Foundation

struct CafeInsight: Identifiable {
    let id = UUID()
    let cafeID: String
    let authorName: String
    let text: String
    let createdAt: Date
    var authorID: String? = nil
    var otherLikeCount: Int = 0
    var isLiked = false

    var likeCount: Int {
        otherLikeCount + (isLiked ? 1 : 0)
    }
}
