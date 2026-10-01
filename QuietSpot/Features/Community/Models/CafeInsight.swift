import Foundation

struct CafeInsight: Identifiable {
    let id = UUID()
    let cafeID: UUID
    let authorName: String
    let text: String
    let createdAt: Date
}
