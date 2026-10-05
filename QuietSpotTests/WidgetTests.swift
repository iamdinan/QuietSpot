import Foundation
import Testing
@testable import QuietSpot

@Suite("Favourite pulse widget data")
@MainActor
struct WidgetTests {
    @Test("Only the three newest favourites are published")
    func selectionAndOrdering() {
        let cafes = (0..<5).map {
            Fixtures.cafe(id: "cafe-\($0)", report: Fixtures.report(offset: Double(-$0)))
        } + [Fixtures.cafe(id: "not-saved", favourite: false, report: Fixtures.report(offset: 60))]
        let content = PulseWidgetPublisher.content(cafes: cafes.reversed())
        #expect(content.state == .ready)
        #expect(content.cafes.map(\.id) == ["cafe-0", "cafe-1", "cafe-2"])
        #expect(content.cafes[0].noise == "Quiet")
        #expect(content.cafes[0].wifi == "Strong Wi‑Fi")
        #expect(content.cafes[0].outlets == "Outlets free")
        #expect(content.cafes[0].crowd == "Uncrowded")
        #expect(content.cafes[0].reportDate == Fixtures.now)
    }

    @Test("Widget status reflects loading, failure, no reports and ready data",
          arguments: [PulseWidgetCafe.Status.loading, .unavailable, .noReports, .ready])
    func statusMapping(status: PulseWidgetCafe.Status) throws {
        var cafe = Fixtures.cafe(report: status == .noReports ? nil : Fixtures.report())
        cafe.isLoadingStatus = status == .loading || status == .unavailable
        cafe.statusErrorMessage = status == .unavailable ? "Failed" : nil
        let result = try #require(PulseWidgetPublisher.content(cafes: [cafe]).cafes.first)
        #expect(result.status == status)
    }

    @Test("No favourites yields an empty ready snapshot")
    func emptyFavourites() {
        #expect(PulseWidgetPublisher.content(cafes: [Fixtures.cafe(favourite: false)]).cafes.isEmpty)
    }

    @Test("Snapshots persist across instances and unchanged content does not overwrite their age")
    func persistenceAndIdempotence() throws {
        let storage = try TestStorage()
        defer { storage.cleanUp() }
        let store = PulseWidgetStore(containerURL: storage.directory)
        let content = PulseWidgetContent(state: .ready, cafes: [Fixtures.widgetCafe()])
        #expect(store.load() == nil)
        #expect(try store.save(content, now: Fixtures.now))
        let restored = PulseWidgetStore(containerURL: storage.directory)
        #expect(restored.load()?.content == content)
        #expect(restored.load()?.savedAt == Fixtures.now)
        #expect(try !restored.save(content, now: Fixtures.now.addingTimeInterval(60)))
        #expect(restored.load()?.savedAt == Fixtures.now)
        #expect(try restored.save(PulseWidgetContent(state: .signedOut), now: Fixtures.now.addingTimeInterval(120)))
        #expect(restored.load()?.content.cafes.isEmpty == true)
        #expect(restored.load()?.content.state == .signedOut)
    }

    @Test("Corrupt snapshots are unavailable and can be replaced with valid content")
    func corruptionRecovery() throws {
        let storage = try TestStorage()
        defer { storage.cleanUp() }
        try Data("broken JSON".utf8).write(to: storage.directory.appendingPathComponent("favorite-pulse.json"))
        let store = PulseWidgetStore(containerURL: storage.directory)
        #expect(store.load() == nil)
        #expect(try store.save(PulseWidgetContent(state: .loading)))
        #expect(store.load()?.content.state == .loading)
    }

    @Test("Missing App Group storage produces an error rather than a false success")
    func missingContainer() {
        let store = PulseWidgetStore(containerURL: nil)
        #expect(store.load() == nil)
        #expect(throws: CocoaError.self) { try store.save(PulseWidgetContent(state: .ready)) }
    }
}
