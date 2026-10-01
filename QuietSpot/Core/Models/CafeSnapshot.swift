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
