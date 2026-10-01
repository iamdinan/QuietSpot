//
//  CafeSnapshot.swift
//  QuietSpot
//

import Foundation

enum NoiseLevel: String {
    case quiet = "Quiet"
    case moderate = "Moderate"
    case loud = "Loud"
}

struct CafeSnapshot: Identifiable {
    let id = UUID()
    let name: String
    let area: String
    let noiseLevel: NoiseLevel
    let wifi: String
    let outlets: String
    let crowd: String
    let updatedAt: String
}

enum HomeSampleData {
    static let favoriteCafes: [CafeSnapshot] = [
        CafeSnapshot(name: "The Glass House", area: "Colombo 07", noiseLevel: .quiet, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded", updatedAt: "5 min ago"),
        CafeSnapshot(name: "Common Grounds", area: "Colombo 03", noiseLevel: .moderate, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Moderate crowd", updatedAt: "18 min ago"),
        CafeSnapshot(name: "The Coffee Stop", area: "Colombo 05", noiseLevel: .loud, wifi: "Spotty Wi‑Fi", outlets: "Outlets full", crowd: "Crowded", updatedAt: "32 min ago"),
        CafeSnapshot(name: "Kopi Kade", area: "Colombo 04", noiseLevel: .quiet, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded", updatedAt: "1 hr ago"),
        CafeSnapshot(name: "Whight & Co.", area: "Colombo 07", noiseLevel: .moderate, wifi: "Strong Wi‑Fi", outlets: "Outlets full", crowd: "Moderate crowd", updatedAt: "2 hrs ago")
    ]
}
