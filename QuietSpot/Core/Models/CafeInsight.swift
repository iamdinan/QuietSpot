// Community post as displayed in the feed, including like state.

import Foundation

struct CafeInsight: Identifiable {
    var id = UUID().uuidString
    let cafeID: String
    var authorName = "Café member"
    var authorPhotoData: Data? = nil
    let text: String
    let createdAt: Date
    let authorID: String
    var likeCount = 0
    var isLiked = false
}
