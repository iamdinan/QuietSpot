import SwiftUI

/// Recalculate elapsed time while the label is visible, without refetching data.
struct CheckInTimeText: View {
    let date: Date?
    let fallback: String
    var prefix = ""

    var body: some View {
        if let date {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text(prefix + CafeCheckInTimeFormatter.string(from: date, relativeTo: context.date))
            }
        } else {
            Text(prefix + fallback)
        }
    }
}
