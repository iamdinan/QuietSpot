import Foundation

@main
struct FavoriteCafeSiriResponseTests {
    @MainActor
    static func main() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let locale = Locale(identifier: "en_US_POSIX")
        func message(_ state: PulseWidgetContent.State, cafes: [PulseWidgetCafe] = [], date: Date = now) -> String {
            FavoriteCafeSiriResponse.message(
                snapshot: PulseWidgetSnapshot(content: PulseWidgetContent(state: state, cafes: cafes), savedAt: now),
                now: date, locale: locale
            )
        }
        func cafe(status: PulseWidgetCafe.Status = .ready, noise: String? = "Quiet", reportDate: Date? = now.addingTimeInterval(-300)) -> PulseWidgetCafe {
            PulseWidgetCafe(id: "cafe", name: "Barista", area: "Colombo", noise: noise,
                            wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded",
                            reportDate: reportDate, status: status)
        }
        assert(FavoriteCafeSiriResponse.message(snapshot: nil).contains("sign in"))
        assert(message(.signedOut).contains("sign in"))
        assert(message(.loading).contains("still loading"))
        assert(message(.unavailable).contains("couldn’t be loaded"))
        assert(message(.ready).contains("haven’t saved"))
        assert(message(.ready, cafes: [cafe(status: .loading)]).contains("still loading"))
        assert(message(.ready, cafes: [cafe(status: .unavailable)]).contains("unavailable"))
        assert(message(.ready, cafes: [cafe(status: .noReports)]).contains("no check-ins"))
        assert(message(.ready, cafes: [cafe(noise: nil)]).contains("incomplete"))
        assert(message(.ready, cafes: [cafe(reportDate: nil)]).contains("incomplete"))

        let response = message(.ready, cafes: [cafe()])
        for text in ["Barista in Colombo", "Noise: Quiet", "Wi-Fi: strong", "Outlets: free",
                     "Crowd: Uncrowded", "5 minutes ago", "Latest saved", "Open QuietSpot to refresh"] {
            assert(response.contains(text), "Missing spoken detail: \(text)")
        }
        assert(message(.ready, cafes: [cafe()], date: now.addingTimeInterval(300)).contains("10 minutes ago"))
        assert(message(.ready, cafes: [cafe(reportDate: now.addingTimeInterval(0.2))]).contains("just now"))
        let older = PulseWidgetCafe(id: "older", name: "Older Café", area: "", noise: "Loud",
                                   wifi: "Spotty Wi‑Fi", outlets: "Outlets full", crowd: "Crowded",
                                   reportDate: now.addingTimeInterval(-3600), status: .ready)
        assert(!message(.ready, cafes: [cafe(), older]).contains("Older Café"), "Only the first, latest favourite is read")
        let negative = message(.ready, cafes: [older])
        assert(negative.contains("Wi-Fi: spotty") && negative.contains("Outlets: full"))
        assert(negative.contains("1 hour ago"))
        print("Siri café response regression checks passed")
    }
}
