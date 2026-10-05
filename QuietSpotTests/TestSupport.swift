import CoreLocation
import Foundation
import Testing
@testable import QuietSpot

/// Fixed data keeps dates, geography and text expectations independent of the simulator.
@MainActor
enum Fixtures {
    static let now = Date(timeIntervalSince1970: 1_800_000_000)
    static let locale = Locale(identifier: "en_US_POSIX")

    static func report(id: String = "report", offset: TimeInterval = 0, noise: NoiseLevel = .quiet,
                       wifi: String = "Strong Wi‑Fi", outlets: String = "Outlets free",
                       crowd: String = "Uncrowded") -> CafeCheckIn {
        CafeCheckIn(id: id, createdAt: now.addingTimeInterval(offset), time: "just now",
                    noiseLevel: noise, wifi: wifi, outlets: outlets, crowd: crowd)
    }

    static func cafe(id: String = "cafe", name: String = "Test Café", favourite: Bool = true,
                     report: CafeCheckIn? = nil) -> CafeSnapshot {
        var cafe = CafeSnapshot(id: id, name: name, area: "Colombo", description: "A café",
                                latitude: 6.9147, longitude: 79.8610, isFavorite: favourite)
        if let report { cafe.updateCheckIns([report]) }
        return cafe
    }

    static func widgetCafe(status: PulseWidgetCafe.Status = .ready) -> PulseWidgetCafe {
        PulseWidgetCafe(id: "cafe", name: "Test Café", area: "Colombo", noise: "Quiet",
                        wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded",
                        reportDate: now.addingTimeInterval(-300), status: status)
    }

    static func post(id: String = "post", offset: TimeInterval = 0, cafeID: String = "cafe") -> CafeInsight {
        CafeInsight(id: id, cafeID: cafeID, authorName: "Alex", text: "Good for studying",
                    createdAt: now.addingTimeInterval(offset), authorID: "author")
    }
}

/// Each persistence test gets its own directory and UserDefaults domain.
struct TestStorage {
    let directory: URL
    let suiteName = "QuietSpotTests." + UUID().uuidString
    let defaults: UserDefaults

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defaults = try #require(UserDefaults(suiteName: suiteName))
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func cleanUp() {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: directory)
    }
}
