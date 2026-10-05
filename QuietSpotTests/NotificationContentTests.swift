import Testing
@testable import QuietSpot

@Suite("Notification wording")
@MainActor
struct NotificationContentTests {
    @Test("Positive conditions form a sentence and retain the café tap identifier")
    func positiveContent() {
        let content = NotificationService.cafeUpdateContent(cafe: Fixtures.cafe(), report: Fixtures.report())
        #expect(content.title == "New check-in at Test Café")
        #expect(content.body == "It’s quiet and uncrowded. Wi-Fi is strong, and outlets are available.")
        #expect(content.userInfo["cafeID"] as? String == "cafe")
        #expect(content.sound != nil)
    }

    @Test("Moderate and loud reports retain negative conditions", arguments: [NoiseLevel.moderate, .loud])
    func negativeContent(noise: NoiseLevel) {
        let report = Fixtures.report(noise: noise, wifi: "Spotty Wi‑Fi", outlets: "Outlets full", crowd: "Crowded")
        let body = NotificationService.cafeUpdateContent(cafe: Fixtures.cafe(), report: report).body
        let description = noise == .moderate ? "moderately noisy" : "loud"
        #expect(body == "It’s \(description) and crowded. Wi-Fi is spotty, and all outlets are in use.")
    }
}
