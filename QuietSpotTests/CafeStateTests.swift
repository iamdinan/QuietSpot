import Foundation
import Testing
@testable import QuietSpot

@Suite("Café state and timestamps")
@MainActor
struct CafeStateTests {
    @Test("The latest report supplies all stats and history is capped at three")
    func latestReportAndHistoryLimit() throws {
        var cafe = Fixtures.cafe()
        cafe.isLoadingStatus = true
        cafe.statusErrorMessage = "Earlier failure"
        let reports = (0..<5).map { Fixtures.report(id: "report-\($0)", offset: Double(-$0), noise: .loud) }
        cafe.updateCheckIns(reports)
        #expect(cafe.recentCheckIns.map(\.id) == ["report-0", "report-1", "report-2"])
        #expect(cafe.noiseLevel == .loud)
        #expect(cafe.wifi == reports[0].wifi)
        #expect(cafe.outlets == reports[0].outlets)
        #expect(cafe.crowd == reports[0].crowd)
        #expect(cafe.updatedAt == reports[0].time)
        #expect(cafe.updateOrder == -Fixtures.now.timeIntervalSince1970)
        #expect(!cafe.isLoadingStatus)
        #expect(cafe.statusErrorMessage == nil)
    }

    @Test("A confirmed empty history clears the previous report")
    func clearingHistory() {
        var cafe = Fixtures.cafe(report: Fixtures.report())
        cafe.updateCheckIns([])
        #expect(cafe.checkInHistory?.isEmpty == true)
        #expect(cafe.noiseLevel == nil && cafe.wifi == nil && cafe.outlets == nil && cafe.crowd == nil)
        #expect(cafe.updatedAt == nil)
        #expect(cafe.updateOrder == .infinity)
    }

    @Test("Sorting puts newer reports first, then uses café names for ties")
    func latestFirstSorting() {
        let old = Fixtures.cafe(id: "old", report: Fixtures.report(offset: -600))
        let newest = Fixtures.cafe(id: "new", report: Fixtures.report())
        let alpha = Fixtures.cafe(id: "a", name: "Alpha")
        let zulu = Fixtures.cafe(id: "z", name: "Zulu")
        #expect([zulu, old, alpha, newest].sorted(by: CafeSnapshot.latestFirst).map(\.id) == ["new", "old", "a", "z"])
    }

    @Test("Relative time handles clock skew and ages without a new report", arguments: [
        (-0.2, "just now"), (0.0, "just now"), (59.0, "just now"),
        (60.0, "1 minute ago"), (300.0, "5 minutes ago"), (3600.0, "1 hour ago"), (86400.0, "1 day ago")
    ])
    func relativeTime(elapsed: Double, expected: String) {
        #expect(CafeCheckInTimeFormatter.string(from: Fixtures.now,
            relativeTo: Fixtures.now.addingTimeInterval(elapsed), locale: Fixtures.locale) == expected)
    }
}
