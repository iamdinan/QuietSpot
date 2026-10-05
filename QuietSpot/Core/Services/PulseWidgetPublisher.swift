import OSLog
import WidgetKit

@MainActor
enum PulseWidgetPublisher {
    static func publish(_ content: PulseWidgetContent) {
        do {
            if try PulseWidgetStore().save(content) {
                WidgetCenter.shared.reloadTimelines(ofKind: PulseWidgetStore.kind)
            }
        } catch {
            Logger(subsystem: "dinan.QuietSpot", category: "PulseWidget")
                .error("Couldn’t share widget snapshot. Check App Group configuration: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func content(cafes: [CafeSnapshot]) -> PulseWidgetContent {
        let favorites = cafes.filter(\.isFavorite).sorted(by: CafeSnapshot.latestFirst).prefix(3)
        return PulseWidgetContent(state: .ready, cafes: favorites.map { cafe in
            let status: PulseWidgetCafe.Status
            if cafe.statusErrorMessage != nil { status = .unavailable }
            else if cafe.isLoadingStatus { status = .loading }
            else if cafe.recentCheckIns.isEmpty { status = .noReports }
            else { status = .ready }
            return PulseWidgetCafe(
                id: cafe.id, name: cafe.name, area: cafe.area,
                noise: cafe.noiseLevel?.rawValue, wifi: cafe.wifi,
                outlets: cafe.outlets, crowd: cafe.crowd,
                reportDate: cafe.recentCheckIns.first?.createdAt, status: status
            )
        })
    }
}
