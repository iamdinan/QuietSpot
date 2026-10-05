import FirebaseFirestore

/// An immutable café report stored in cafes/{cafeID}/checkIns/{checkInID}.
struct CafeCheckInDocument: Decodable {
    let createdAt: Timestamp
    let noiseLevel: NoiseLevel
    let wifi: String
    let outlets: String
    let crowd: String
}
