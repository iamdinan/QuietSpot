import Foundation

@main
struct CafeCheckInTimeFormatterTests {
    static func main() {
        let submittedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let locale = Locale(identifier: "en_US_POSIX")
        func label(after elapsed: TimeInterval) -> String {
            CafeCheckInTimeFormatter.string(
                from: submittedAt, relativeTo: submittedAt.addingTimeInterval(elapsed), locale: locale
            )
        }
        assert(label(after: -0.2) == "just now", "Server clock drift must not show in 0 seconds")
        assert(label(after: 0) == "just now")
        assert(label(after: 59) == "just now")
        assert(label(after: 60) == "1 minute ago")
        assert(label(after: 300) == "5 minutes ago", "The same report must age without a new snapshot")
        assert(label(after: 3600) == "1 hour ago")
        assert(label(after: 86400) == "1 day ago")
        print("Check-in timestamp regression checks passed")
    }
}
