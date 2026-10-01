import Foundation

struct CafeCheckIn: Identifiable {
    let id = UUID()
    let time: String
    let noiseLevel: NoiseLevel
    let wifi: String
    let outlets: String
    let crowd: String
}
