import SwiftUI
import WidgetKit

struct PulseEntry: TimelineEntry {
    let date: Date
    let snapshot: PulseWidgetSnapshot?

    static var example: PulseEntry {
        let cafes = ["Barista · Ward Place", "Common Grounds", "Coffee Stop"].enumerated().map { index, name in
            PulseWidgetCafe(id: "preview-\(index)", name: name, area: "Colombo",
                            noise: index == 1 ? "Moderate" : "Quiet", wifi: "Strong Wi‑Fi",
                            outlets: "Outlets free", crowd: "Uncrowded",
                            reportDate: .now.addingTimeInterval(-Double((index + 1) * 300)), status: .ready)
        }
        return PulseEntry(date: .now, snapshot: PulseWidgetSnapshot(
            content: PulseWidgetContent(state: .ready, cafes: cafes), savedAt: .now
        ))
    }
}

struct PulseProvider: TimelineProvider {
    func placeholder(in context: Context) -> PulseEntry { .example }

    func getSnapshot(in context: Context, completion: @escaping (PulseEntry) -> Void) {
        completion(context.isPreview ? .example : PulseEntry(date: .now, snapshot: PulseWidgetStore().load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PulseEntry>) -> Void) {
        let now = Date()
        let snapshot = PulseWidgetStore().load()
        // Age the labels without fetching data. The app requests a new timeline
        // when its shared data changes; iOS decides when to render those updates.
        let entries = (0..<60).map { minute in
            PulseEntry(date: now.addingTimeInterval(Double(minute) * 60), snapshot: snapshot)
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(3600))))
    }
}

@main
struct FavoritePulseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: PulseWidgetStore.kind, provider: PulseProvider()) { entry in
            PulseWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Favorite café pulse")
        .description("Your latest favourite café check-ins: noise, Wi-Fi, outlets, and crowd.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct PulseWidgetEntryView: View {
    let entry: PulseEntry
    @Environment(\.widgetFamily) private var family

    var body: some View { FavoritePulseView(entry: entry, family: family) }
}

struct FavoritePulseView: View {
    let entry: PulseEntry
    let family: WidgetFamily
    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color {
        colorScheme == .dark ? Color(red: 0.650, green: 0.835, blue: 0.700) : Color(red: 0.220, green: 0.360, blue: 0.290)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 10) {
            HStack(spacing: 5) {
                Image(systemName: "waveform.path")
                Text(family == .systemSmall ? "Café pulse" : "Favorite café pulse")
                    .lineLimit(1).minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(accent)
            .accessibilityAddTraits(.isHeader)

            if let content = entry.snapshot?.content, content.state == .ready, !content.cafes.isEmpty {
                let cafes = Array(content.cafes.prefix(family == .systemLarge ? 3 : 1))
                ForEach(Array(cafes.enumerated()), id: \.element.id) { index, cafe in
                    if index > 0 { Divider() }
                    cafeRow(cafe)
                }
                Spacer(minLength: 0)
                if family != .systemSmall {
                    Text("Last synced from QuietSpot · Open to refresh")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
            } else {
                Spacer(minLength: 0)
                emptyState
                Spacer(minLength: 0)
            }
        }
        .privacySensitive()
    }

    private func cafeRow(_ cafe: PulseWidgetCafe) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                if family == .systemMedium {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.title2).foregroundStyle(accent)
                        .frame(width: 42, height: 42)
                        .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(cafe.name)
                        .font(family == .systemSmall ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                        .lineLimit(1).minimumScaleFactor(0.8)
                    if family == .systemMedium {
                        Text(cafe.area).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    if let date = cafe.reportDate {
                        Text("Updated " + CafeCheckInTimeFormatter.string(from: date, relativeTo: entry.date))
                            .font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            }

            if cafe.status == .ready, let noise = cafe.noise, let wifi = cafe.wifi,
               let outlets = cafe.outlets, let crowd = cafe.crowd {
                LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 4) {
                    pill(noise, symbol: "speaker.wave.2", factor: "Noise", fullValue: noise,
                         positive: noise == "Quiet", moderate: noise == "Moderate")
                    pill(family == .systemSmall ? (wifi == "Strong Wi‑Fi" ? "Strong" : "Spotty") : (wifi == "Strong Wi‑Fi" ? "Strong Wi-Fi" : "Spotty Wi-Fi"), symbol: "wifi", factor: "Wi-Fi", fullValue: wifi,
                         positive: wifi == "Strong Wi‑Fi")
                    pill(family == .systemSmall ? (outlets == "Outlets free" ? "Free" : "Full") : outlets, symbol: "powerplug", factor: "Outlets", fullValue: outlets,
                         positive: outlets == "Outlets free")
                    pill(family == .systemSmall ? (crowd == "Uncrowded" ? "Low" : "High") : crowd, symbol: "person.2", factor: "Crowd", fullValue: crowd, positive: crowd == "Uncrowded")
                }
            } else {
                Label(cafe.status == .loading ? "Loading stats…" : cafe.status == .unavailable ? "Stats unavailable" : "No check-ins yet",
                      systemImage: cafe.status == .unavailable ? "exclamationmark.triangle" : "clock")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func pill(_ title: String, symbol: String, factor: String, fullValue: String, positive: Bool, moderate: Bool = false) -> some View {
        let tint: Color = moderate
            ? (colorScheme == .dark ? Color(red: 1, green: 0.73, blue: 0.32) : Color(red: 0.52, green: 0.27, blue: 0.02))
            : positive
                ? (colorScheme == .dark ? Color(red: 0.45, green: 0.88, blue: 0.59) : Color(red: 0.08, green: 0.38, blue: 0.20))
                : (colorScheme == .dark ? Color(red: 1, green: 0.68, blue: 0.70) : Color(red: 0.60, green: 0.09, blue: 0.12))
        return Label(title, systemImage: symbol)
            .font(.system(size: family == .systemSmall ? 10 : 11, weight: .semibold))
            .lineLimit(1).minimumScaleFactor(0.75)
            .foregroundStyle(tint)
            .padding(.horizontal, 5).padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.12), in: Capsule())
            .accessibilityLabel("\(factor): \(fullValue)")
    }

    private var emptyState: some View {
        let state = entry.snapshot?.content.state
        let title: String
        let detail: String
        switch state {
        case .signedOut:
            title = "Sign in to QuietSpot"
            detail = "Your favourites will appear here."
        case .loading:
            title = "Loading your favourites"
            detail = "Open QuietSpot to finish syncing."
        case .ready:
            title = "Save your first café"
            detail = "Tap a café’s heart in QuietSpot."
        case .unavailable:
            title = "Favourites unavailable"
            detail = "Open QuietSpot to try again."
        case nil:
            title = "Your café pulse"
            detail = "Open QuietSpot to sync your favourites."
        }
        return VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "cup.and.saucer.fill").foregroundStyle(accent)
            Text(title)
                .font(family == .systemSmall ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(detail).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview(as: .systemSmall) { FavoritePulseWidget() } timeline: { PulseEntry.example }
#Preview(as: .systemMedium) { FavoritePulseWidget() } timeline: { PulseEntry.example }
#Preview(as: .systemLarge) { FavoritePulseWidget() } timeline: { PulseEntry.example }
