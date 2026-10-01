import FirebaseFirestore

/// Shared café metadata from Firestore. Favorites and check-ins are separate records.
struct CafeDocument: Decodable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let area: String
    let description: String
    let imageURL: String
    let location: GeoPoint
}
