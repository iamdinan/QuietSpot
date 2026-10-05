import Foundation

enum CafeCheckInTimeFormatter {
    static func string(from date: Date, relativeTo now: Date = .now, locale: Locale = .current) -> String {
        // A freshly acknowledged server timestamp can be slightly ahead of the
        // device clock. Reports describe past events, so never show a countdown.
        guard now.timeIntervalSince(date) >= 60 else { return "just now" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .numeric
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
