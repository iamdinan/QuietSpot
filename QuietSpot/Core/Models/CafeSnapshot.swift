//
//  CafeSnapshot.swift
//  QuietSpot
//

import Foundation
import CoreLocation

enum NoiseLevel: String, CaseIterable {
    case quiet = "Quiet"
    case moderate = "Moderate"
    case loud = "Loud"
}

struct CafeSnapshot: Identifiable {
    var id: String = UUID().uuidString
    let name: String
    let area: String
    let description: String
    var imageName: String = ""
    let latitude: Double
    let longitude: Double
    var isFavorite: Bool = false
    var updateOrder: Double = .infinity
    var noiseLevel: NoiseLevel? = nil
    var wifi: String? = nil
    var outlets: String? = nil
    var crowd: String? = nil
    var updatedAt: String? = nil
    var checkInHistory: [CafeCheckIn]? = nil
    var imageURL: String? = nil

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var recentCheckIns: [CafeCheckIn] {
        if let checkInHistory { return checkInHistory }
        guard let updatedAt, let noiseLevel, let wifi, let outlets, let crowd else { return [] }
        return [CafeCheckIn(time: updatedAt, noiseLevel: noiseLevel, wifi: wifi, outlets: outlets, crowd: crowd)]
    }

    nonisolated static func latestFirst(_ lhs: Self, _ rhs: Self) -> Bool {
        if lhs.updateOrder != rhs.updateOrder { return lhs.updateOrder < rhs.updateOrder }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
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
