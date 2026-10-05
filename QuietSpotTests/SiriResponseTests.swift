import Foundation
import Testing
@testable import QuietSpot

@Suite("Saved café Siri responses")
@MainActor
struct SiriResponseTests {
    private func message(_ state: PulseWidgetContent.State = .ready, cafes: [PulseWidgetCafe] = []) -> String {
        FavoriteCafeSiriResponse.message(snapshot: PulseWidgetSnapshot(
            content: PulseWidgetContent(state: state, cafes: cafes), savedAt: Fixtures.now),
            now: Fixtures.now, locale: Fixtures.locale)
    }

    @Test("Unavailable account snapshots give actionable responses",
          arguments: [PulseWidgetContent.State.signedOut, .loading, .unavailable, .ready])
    func accountStates(state: PulseWidgetContent.State) {
        let response = message(state)
        switch state {
        case .signedOut: #expect(response.contains("sign in"))
        case .loading: #expect(response.contains("still loading"))
        case .unavailable: #expect(response.contains("couldn’t be loaded"))
        case .ready: #expect(response.contains("haven’t saved"))
        }
    }

    @Test("No snapshot asks the user to sync")
    func missingSnapshot() {
        #expect(FavoriteCafeSiriResponse.message(snapshot: nil).contains("sync"))
    }

    @Test("Incomplete and unavailable reports never invent stats",
          arguments: [PulseWidgetCafe.Status.loading, .unavailable, .noReports])
    func reportStates(status: PulseWidgetCafe.Status) {
        let response = message(cafes: [Fixtures.widgetCafe(status: status)])
        let expected = status == .loading ? "still loading" : status == .unavailable ? "unavailable" : "no check-ins"
        #expect(response.contains(expected))
        #expect(!response.contains("Noise:"))
    }

    @Test("Missing required fields produce an incomplete-report response", arguments: ["noise", "date"])
    func incompleteReport(field: String) {
        let cafe = PulseWidgetCafe(id: "cafe", name: "Test Café", area: "Colombo",
            noise: field == "noise" ? nil : "Quiet", wifi: "Strong Wi‑Fi", outlets: "Outlets free",
            crowd: "Uncrowded", reportDate: field == "date" ? nil : Fixtures.now, status: .ready)
        #expect(message(cafes: [cafe]).contains("incomplete"))
    }

    @Test("Only the first favourite is read, including all stats, age and saved-data context")
    func savedReportDetails() {
        let other = PulseWidgetCafe(id: "other", name: "Other Café", area: "", noise: "Loud",
            wifi: "Spotty Wi‑Fi", outlets: "Outlets full", crowd: "Crowded", reportDate: Fixtures.now, status: .ready)
        let response = message(cafes: [Fixtures.widgetCafe(), other])
        for detail in ["Test Café in Colombo", "Noise: Quiet", "Wi-Fi: strong", "Outlets: free",
                       "Crowd: Uncrowded", "5 minutes ago", "Latest saved", "Open QuietSpot to refresh"] {
            #expect(response.contains(detail))
        }
        #expect(!response.contains("Other Café"))
        let negative = message(cafes: [other])
        #expect(negative.contains("Wi-Fi: spotty"))
        #expect(negative.contains("Outlets: full"))
        #expect(!negative.contains("Other Café in"))
    }
}
