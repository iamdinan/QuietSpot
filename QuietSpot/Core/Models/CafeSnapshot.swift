//
//  CafeSnapshot.swift
//  QuietSpot
//

import Foundation
import CoreLocation

enum NoiseLevel: String, CaseIterable, Codable {
    case quiet = "Quiet"
    case moderate = "Moderate"
    case loud = "Loud"
}

struct CafeSnapshot: Identifiable {
    var id: String = UUID().uuidString
    let name: String
    let area: String
    let description: String
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
    var isLoadingStatus = false
    var statusErrorMessage: String? = nil

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var recentCheckIns: [CafeCheckIn] {
        checkInHistory ?? []
    }

    nonisolated static func latestFirst(_ lhs: Self, _ rhs: Self) -> Bool {
        if lhs.updateOrder != rhs.updateOrder { return lhs.updateOrder < rhs.updateOrder }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    mutating func updateCheckIns(_ checkIns: [CafeCheckIn]) {
        checkInHistory = Array(checkIns.prefix(3))
        let latest = checkInHistory?.first
        noiseLevel = latest?.noiseLevel
        wifi = latest?.wifi
        outlets = latest?.outlets
        crowd = latest?.crowd
        updatedAt = latest?.time
        updateOrder = latest?.createdAt.map { -$0.timeIntervalSince1970 } ?? .infinity
        isLoadingStatus = false
        statusErrorMessage = nil
    }
}
