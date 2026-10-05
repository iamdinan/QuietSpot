import Foundation

@main
struct PulseWidgetTests {
    @MainActor
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = PulseWidgetStore(containerURL: directory)
        assert(store.load() == nil)

        let now = Date(timeIntervalSince1970: 1_800_000_000)
        func cafe(_ id: String, age: Double, favorite: Bool = true) -> CafeSnapshot {
            var cafe = CafeSnapshot(id: id, name: id, area: "Colombo", description: "",
                                    latitude: 6.9, longitude: 79.8, isFavorite: favorite)
            cafe.updateCheckIns([CafeCheckIn(id: "report-\(id)", createdAt: now.addingTimeInterval(-age),
                                            time: "stale text", noiseLevel: .quiet, wifi: "Strong Wi‑Fi",
                                            outlets: "Outlets free", crowd: "Uncrowded")])
            return cafe
        }
        let content = PulseWidgetPublisher.content(cafes: [
            cafe("oldest", age: 400), cafe("second", age: 200), cafe("newest", age: 100),
            cafe("third", age: 300), cafe("not-favorite", age: 0, favorite: false)
        ])
        assert(content.cafes.map(\.id) == ["newest", "second", "third"])
        assert(content.cafes.first?.reportDate == now.addingTimeInterval(-100))
        assert(content.cafes.first?.wifi == "Strong Wi‑Fi")
        let wrote = try store.save(content, now: now)
        assert(wrote)
        assert(store.load()?.content == content, "Snapshot must round-trip through shared storage")
        let unchanged = try store.save(content, now: now.addingTimeInterval(60))
        assert(!unchanged, "Unchanged data must not request another widget reload")
        assert(store.load()?.savedAt == now)

        let cleared = try store.save(PulseWidgetContent(state: .signedOut))
        assert(cleared)
        assert(store.load()?.content.state == .signedOut)
        assert(store.load()?.content.cafes.isEmpty == true, "Sign-out must remove the previous favourites")
        try store.save(PulseWidgetContent(state: .loading))
        assert(store.load()?.content.cafes.isEmpty == true, "New accounts must start without old data")

        var empty = cafe("empty", age: 0)
        empty.updateCheckIns([])
        assert(PulseWidgetPublisher.content(cafes: [empty]).cafes.first?.status == .noReports)
        empty.isLoadingStatus = true
        assert(PulseWidgetPublisher.content(cafes: [empty]).cafes.first?.status == .loading)
        empty.statusErrorMessage = "Network error"
        assert(PulseWidgetPublisher.content(cafes: [empty]).cafes.first?.status == .unavailable)
        assert(PulseWidgetPublisher.content(cafes: []).cafes.isEmpty)

        try Data("broken cache".utf8).write(to: directory.appendingPathComponent("favorite-pulse.json"))
        assert(store.load() == nil, "Corrupt snapshots must fall back to an honest empty state")
        do {
            try PulseWidgetStore(containerURL: nil).save(content)
            assertionFailure("Missing App Group container must be reported")
        } catch {}
        print("Pulse widget regression checks passed")
    }
}
