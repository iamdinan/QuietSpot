//
//  CafeSnapshot.swift
//  QuietSpot
//

import Foundation

enum NoiseLevel: String, CaseIterable {
    case quiet = "Quiet"
    case moderate = "Moderate"
    case loud = "Loud"
}

struct CafeSnapshot: Identifiable {
    let id = UUID()
    let name: String
    let area: String
    let imageName: String
    var isFavorite: Bool
    var updateOrder: Double
    var noiseLevel: NoiseLevel
    var wifi: String
    var outlets: String
    var crowd: String
    var updatedAt: String
    var checkInHistory: [CafeCheckIn]? = nil

    // Sample history until check-ins are supplied by Firebase.
    var recentCheckIns: [CafeCheckIn] {
        checkInHistory ?? [
            CafeCheckIn(time: updatedAt, noiseLevel: noiseLevel, wifi: wifi, outlets: outlets, crowd: crowd),
            CafeCheckIn(time: "3 hrs ago", noiseLevel: .moderate, wifi: "Strong Wi‑Fi", outlets: "Outlets full", crowd: "Crowded"),
            CafeCheckIn(time: "5 hrs ago", noiseLevel: .quiet, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded")
        ]
    }

    mutating func record(_ checkIn: CafeCheckIn) {
        checkInHistory = Array(([checkIn] + recentCheckIns).prefix(3))
        noiseLevel = checkIn.noiseLevel
        wifi = checkIn.wifi
        outlets = checkIn.outlets
        crowd = checkIn.crowd
        updatedAt = checkIn.time
        updateOrder = -Date.now.timeIntervalSince1970
    }
}

struct CafeCheckIn: Identifiable {
    let id = UUID()
    let time: String
    let noiseLevel: NoiseLevel
    let wifi: String
    let outlets: String
    let crowd: String
}

enum HomeSampleData {
    static let cafes: [CafeSnapshot] = [
        CafeSnapshot(name: "The Glass House", area: "Colombo 07", imageName: "CafeGlassHouse", isFavorite: true, updateOrder: 2, noiseLevel: .quiet, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded", updatedAt: "5 min ago"),
        CafeSnapshot(name: "Common Grounds", area: "Colombo 03", imageName: "CafeCommonGrounds", isFavorite: true, updateOrder: 4, noiseLevel: .moderate, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded", updatedAt: "18 min ago"),
        CafeSnapshot(name: "The Coffee Stop", area: "Colombo 05", imageName: "CafeCoffeeStop", isFavorite: false, updateOrder: 1, noiseLevel: .loud, wifi: "Spotty Wi‑Fi", outlets: "Outlets full", crowd: "Crowded", updatedAt: "2 min ago"),
        CafeSnapshot(name: "Kopi Kade", area: "Colombo 04", imageName: "CafeKopiKade", isFavorite: true, updateOrder: 3, noiseLevel: .quiet, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded", updatedAt: "12 min ago"),
        CafeSnapshot(name: "Whight & Co.", area: "Colombo 07", imageName: "CafeWhightCo", isFavorite: false, updateOrder: 5, noiseLevel: .moderate, wifi: "Strong Wi‑Fi", outlets: "Outlets full", crowd: "Crowded", updatedAt: "2 hrs ago")
    ]
}
