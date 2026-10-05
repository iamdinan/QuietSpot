import Foundation

nonisolated struct PulseWidgetCafe: Codable, Equatable, Identifiable {
    enum Status: String, Codable { case ready, loading, unavailable, noReports }
    let id: String
    let name: String
    let area: String
    let noise: String?
    let wifi: String?
    let outlets: String?
    let crowd: String?
    let reportDate: Date?
    let status: Status
}

nonisolated struct PulseWidgetContent: Codable, Equatable {
    enum State: String, Codable { case signedOut, loading, ready, unavailable }
    var state: State
    var cafes: [PulseWidgetCafe] = []
}

nonisolated struct PulseWidgetSnapshot: Codable {
    let content: PulseWidgetContent
    let savedAt: Date
}

/// Small, atomic snapshot shared by the app and its extension. No auth tokens,
/// profile data, Firebase dependencies, or network access belong in the widget.
nonisolated struct PulseWidgetStore {
    static let appGroup = "group.dinan.QuietSpot"
    static let kind = "QuietSpotFavoritePulse"
    private let containerURL: URL?

    init(containerURL: URL? = sharedContainerURL) {
        self.containerURL = containerURL
    }

    private static var sharedContainerURL: URL? {
        #if os(iOS)
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
        #else
        nil
        #endif
    }

    func load() -> PulseWidgetSnapshot? {
        guard let containerURL,
              let data = try? Data(contentsOf: containerURL.appendingPathComponent("favorite-pulse.json")) else { return nil }
        return try? JSONDecoder().decode(PulseWidgetSnapshot.self, from: data)
    }

    @discardableResult
    func save(_ content: PulseWidgetContent, now: Date = .now) throws -> Bool {
        guard let containerURL else { throw CocoaError(.fileNoSuchFile) }
        guard load()?.content != content else { return false }
        let snapshot = PulseWidgetSnapshot(content: content, savedAt: now)
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: containerURL.appendingPathComponent("favorite-pulse.json"), options: .atomic)
        return true
    }
}
