import Foundation

/// Tracks confirmed reports independently of favourites and location so changing
/// eligibility never replays an old report as a new update.
struct CafeStatUpdateTracker {
    private struct Baseline {
        var report: CafeCheckIn?
    }

    private var baselines: [String: Baseline] = [:]

    mutating func consume(cafeID: String, latest: CafeCheckIn?) -> CafeCheckIn? {
        guard let baseline = baselines[cafeID] else {
            baselines[cafeID] = Baseline(report: latest)
            return nil
        }
        // Empty snapshots and older reports must not move the baseline backwards.
        guard let latest, let date = latest.createdAt else { return nil }
        if let previous = baseline.report {
            guard latest.id != previous.id,
                  date > (previous.createdAt ?? .distantPast) else { return nil }
        }
        baselines[cafeID] = Baseline(report: latest)
        guard let previous = baseline.report else { return latest }
        let changed = latest.noiseLevel != previous.noiseLevel
            || latest.wifi != previous.wifi
            || latest.outlets != previous.outlets
            || latest.crowd != previous.crowd
        return changed ? latest : nil
    }
}
