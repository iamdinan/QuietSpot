import FirebaseFirestore

struct CafeInsightDocument: Decodable {
    let cafeID: String
    let authorID: String
    let text: String
    let createdAt: Timestamp
    let likeCount: Int
}
