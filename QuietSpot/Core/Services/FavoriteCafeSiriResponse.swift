import Foundation

/// Uses the same last-synced reports as the widget; it never invents live stats.
enum FavoriteCafeSiriResponse {
    static func message(snapshot: PulseWidgetSnapshot?, now: Date = .now, locale: Locale = .current) -> String {
        guard let snapshot else { return "Open QuietSpot and sign in to sync your favourite cafés first." }
        switch snapshot.content.state {
        case .signedOut:
            return "Please sign in to QuietSpot to check your favourite cafés."
        case .loading:
            return "Your favourites are still loading. Open QuietSpot to finish syncing."
        case .unavailable:
            return "Your favourites couldn’t be loaded. Open QuietSpot to try again."
        case .ready: break
        }
        guard let cafe = snapshot.content.cafes.first else {
            return "You haven’t saved any favourite cafés yet. Open QuietSpot and tap a café’s heart."
        }
        switch cafe.status {
        case .loading:
            return "Stats for \(cafe.name) are still loading. Open QuietSpot to finish syncing."
        case .unavailable:
            return "Stats for \(cafe.name) are unavailable. Open QuietSpot to try again."
        case .noReports:
            return "\(cafe.name) has no check-ins yet."
        case .ready: break
        }
        guard let noise = cafe.noise, let wifi = cafe.wifi,
              let outlets = cafe.outlets, let crowd = cafe.crowd,
              let date = cafe.reportDate else {
            return "The saved report for \(cafe.name) is incomplete. Open QuietSpot to refresh it."
        }
        let age = CafeCheckInTimeFormatter.string(from: date, relativeTo: now, locale: locale)
        let wifiQuality = wifi == "Strong Wi‑Fi" ? "strong" : wifi == "Spotty Wi‑Fi" ? "spotty" : wifi
        let outletAvailability = outlets == "Outlets free" ? "free" : outlets == "Outlets full" ? "full" : outlets
        let area = cafe.area.isEmpty ? "" : " in \(cafe.area)"
        return "Latest saved check-in for \(cafe.name)\(area): Noise: \(noise). Wi-Fi: \(wifiQuality). Outlets: \(outletAvailability). Crowd: \(crowd). Reported \(age). Open QuietSpot to refresh."
    }
}
