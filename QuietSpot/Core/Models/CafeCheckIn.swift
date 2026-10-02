import Foundation

struct CafeCheckIn: Identifiable {
    var id: String = UUID().uuidString
    var createdAt: Date? = nil
    let time: String
    let noiseLevel: NoiseLevel
    let wifi: String
    let outlets: String
    let crowd: String
}
